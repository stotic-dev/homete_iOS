import {randomUUID} from "crypto";
import {
  getFirestore,
  FieldValue,
  Timestamp,
} from "firebase-admin/firestore";
import {FirestoreCollections} from "./FirestoreCollections";
import {AccountConverter, AccountFields} from "./Account";
import {CohabitantConverter, CohabitantFields} from "./Cohabitant";
import {InvitationConverter, InvitationFields} from "./Invitation";
import {
  NotificationSender,
  NotifyResult,
  notifyOtherCohabitants,
} from "./CohabitantNotifier";

/** 招待リンクの有効期間（24時間） */
export const INVITATION_EXPIRATION_MS = 24 * 60 * 60 * 1000;

/** 招待処理で発生しうるエラーの種別 */
export type InvitationErrorCode =
    | "account-not-found"
    | "invitation-not-found"
    | "invitation-expired"
    | "already-joined"
    | "cohabitant-not-found";

/**
 * 招待処理の失敗を表すエラー
 *
 * callable側でHttpsErrorに変換するため、ドメイン都合のコードを持たせている。
 */
export class InvitationError extends Error {
  /**
   * @param {InvitationErrorCode} code エラー種別
   * @param {string} message エラーメッセージ
   */
  constructor(readonly code: InvitationErrorCode, message: string) {
    super(message);
    this.name = "InvitationError";
  }
}

/** 発行された招待の内容 */
export interface IssuedInvitation {
    token: string;
    /** 招待先のグループID（発行者がグループ未所属の場合はnull） */
    cohabitantId: string | null;
    /** 有効期限（epochミリ秒） */
    expiresAt: number;
}

/**
 * 招待トークンを発行する
 *
 * 発行時にはグループを作らない。発行者がグループ未所属の場合はcohabitantIdをnullで
 * 保存し、参加者が現れた時点（joinCohabitantByInvitation）で発行者と参加者のグループを作る。
 * 発行時に作ると、リンクを共有しなかった・誰も参加しなかった場合に
 * 本人だけのグループが残り、グループ未参加なのに参加済みとして振る舞ってしまうため。
 * @param {string} userId 発行する本人のユーザーID
 * @param {Date} now 実行日時
 * @return {Promise<IssuedInvitation>} 発行した招待
 */
export async function issueInvitation(
  userId: string,
  now: Date
): Promise<IssuedInvitation> {
  const db = getFirestore();
  const token = randomUUID();
  const expiresAt = new Date(now.getTime() + INVITATION_EXPIRATION_MS);

  const accountSnapshot = await db
    .collection(FirestoreCollections.ACCOUNT)
    .where(AccountFields.ID, "==", userId)
    .limit(1)
    .get();

  if (accountSnapshot.empty) {
    throw new InvitationError(
      "account-not-found",
      `Account for user ${userId} was not found.`
    );
  }

  const account = AccountConverter.fromFirestoreData(
    accountSnapshot.docs[0].data()
  );
  const cohabitantId = account.cohabitantId ?? null;

  await db
    .collection(FirestoreCollections.INVITATION)
    .doc(token)
    .set({
      [InvitationFields.COHABITANT_ID]: cohabitantId,
      [InvitationFields.CREATED_BY]: userId,
      [InvitationFields.CREATED_AT]: Timestamp.fromDate(now),
      [InvitationFields.EXPIRES_AT]: Timestamp.fromDate(expiresAt),
    });

  return {token, cohabitantId, expiresAt: expiresAt.getTime()};
}

/** 参加前に表示する招待の概要 */
export interface InvitationSummary {
    /** 招待者の表示名（アカウントが無い・名前未設定なら null） */
    inviterName: string | null;
    /** 招待先のグループID（発行者がグループ未所属の場合はnull） */
    cohabitantId: string | null;
    /** 有効期限（epochミリ秒） */
    expiresAt: number;
}

/**
 * 参加前に表示するための招待の概要を取得する
 *
 * 「〇〇さんのグループに参加しますか？」の確認画面で使う。参加を実行しないため
 * トランザクションは不要だが、無効・期限切れの判定は joinCohabitantByInvitation と
 * 同じ基準で行い、参加ボタンを押す前に失敗が分かるようにする。
 * @param {string} token 招待トークン
 * @param {Date} now 実行日時
 * @return {Promise<InvitationSummary>} 招待の概要
 */
export async function fetchInvitation(
  token: string,
  now: Date
): Promise<InvitationSummary> {
  const db = getFirestore();

  const invitationSnapshot = await db
    .collection(FirestoreCollections.INVITATION)
    .doc(token)
    .get();
  const invitation = InvitationConverter.fromFirestore(invitationSnapshot);

  if (!invitation) {
    throw new InvitationError(
      "invitation-not-found",
      `Invitation ${token} was not found.`
    );
  }

  if (invitation.expiresAt.getTime() <= now.getTime()) {
    throw new InvitationError(
      "invitation-expired",
      `Invitation ${token} has already expired.`
    );
  }

  const inviterSnapshot = await db
    .collection(FirestoreCollections.ACCOUNT)
    .where(AccountFields.ID, "==", invitation.createdBy)
    .limit(1)
    .get();
  const inviter = inviterSnapshot.empty ?
    null :
    AccountConverter.fromFirestoreData(inviterSnapshot.docs[0].data());

  return {
    inviterName: inviter?.userName ?? null,
    cohabitantId: invitation.cohabitantId ?? inviter?.cohabitantId ?? null,
    expiresAt: invitation.expiresAt.getTime(),
  };
}

/** 招待による参加の結果 */
export interface JoinResult {
    /** 参加したグループのID */
    cohabitantId: string;
    /**
     * この呼び出しでメンバーが増えたか
     *
     * 同じグループへの再参加（リンクの再タップ）はfalse。
     * 参加通知を送るかどうかの判断に使う。
     */
    joined: boolean;
    /** 参加者の表示名（通知本文に使う） */
    userName?: string;
}

/**
 * 招待トークンを使ってグループに参加する
 *
 * トークンの検証からメンバー追加・アカウント更新までをトランザクションで行う。
 * 招待にグループが紐づいていない（発行者が未所属だった）場合は、
 * ここで発行者と参加者の2人からなるグループを新規作成する。
 * 同じ招待からの2人目以降も同じグループへ参加できるよう、作成したグループIDは
 * 招待にも書き戻す。
 * すでに同じグループへ参加済みの場合は、リンクの再タップを想定して
 * 書き込みを行わず成功として扱う。
 * @param {string} userId 参加する本人のユーザーID
 * @param {string} token 招待トークン
 * @param {Date} now 実行日時
 * @return {Promise<JoinResult>} 参加結果
 */
export async function joinCohabitantByInvitation(
  userId: string,
  token: string,
  now: Date
): Promise<JoinResult> {
  const db = getFirestore();

  return await db.runTransaction(async (transaction) => {
    const invitationRef = db
      .collection(FirestoreCollections.INVITATION)
      .doc(token);
    const invitationSnapshot = await transaction.get(invitationRef);
    const invitation = InvitationConverter.fromFirestore(invitationSnapshot);

    if (!invitation) {
      throw new InvitationError(
        "invitation-not-found",
        `Invitation ${token} was not found.`
      );
    }

    if (invitation.expiresAt.getTime() <= now.getTime()) {
      throw new InvitationError(
        "invitation-expired",
        `Invitation ${token} has already expired.`
      );
    }

    const accountQuery = db
      .collection(FirestoreCollections.ACCOUNT)
      .where(AccountFields.ID, "==", userId)
      .limit(1);
    const accountSnapshot = await transaction.get(accountQuery);

    if (accountSnapshot.empty) {
      throw new InvitationError(
        "account-not-found",
        `Account for user ${userId} was not found.`
      );
    }

    const accountDoc = accountSnapshot.docs[0];
    const account = AccountConverter.fromFirestoreData(accountDoc.data());

    // 発行者が招待の後にグループへ参加している場合は、そのグループへ案内する
    const inviterQuery = db
      .collection(FirestoreCollections.ACCOUNT)
      .where(AccountFields.ID, "==", invitation.createdBy)
      .limit(1);
    const inviterSnapshot = await transaction.get(inviterQuery);
    const inviterDoc = inviterSnapshot.empty ? null : inviterSnapshot.docs[0];
    const inviter = inviterDoc ?
      AccountConverter.fromFirestoreData(inviterDoc.data()) :
      null;
    const targetCohabitantId =
      invitation.cohabitantId ?? inviter?.cohabitantId ?? null;

    if (account.cohabitantId) {
      // 同じグループへの再参加は、リンクを再度開いただけなので成功扱いにする
      if (account.cohabitantId === targetCohabitantId) {
        return {
          cohabitantId: account.cohabitantId,
          joined: false,
          userName: account.userName,
        };
      }

      throw new InvitationError(
        "already-joined",
        `User ${userId} already belongs to another cohabitant group.`
      );
    }

    if (targetCohabitantId) {
      const cohabitantRef = db
        .collection(FirestoreCollections.COHABITANT)
        .doc(targetCohabitantId);
      const cohabitantSnapshot = await transaction.get(cohabitantRef);
      const cohabitant = CohabitantConverter.fromFirestore(cohabitantSnapshot);

      if (!cohabitant) {
        throw new InvitationError(
          "cohabitant-not-found",
          `Cohabitant ${targetCohabitantId} was not found.`
        );
      }

      transaction.update(cohabitantRef, {
        [CohabitantFields.MEMBERS]: FieldValue.arrayUnion(userId),
      });
      transaction.update(accountDoc.ref, {
        [AccountFields.COHABITANT_ID]: targetCohabitantId,
      });

      return {
        cohabitantId: targetCohabitantId,
        joined: true,
        userName: account.userName,
      };
    }

    // 発行者が退会している、または本人が自分の招待を開いた場合は参加先を作れない
    if (!inviterDoc || invitation.createdBy === userId) {
      throw new InvitationError(
        "cohabitant-not-found",
        `Cohabitant for invitation ${token} cannot be created.`
      );
    }

    const cohabitantId = randomUUID();
    const cohabitantRef = db
      .collection(FirestoreCollections.COHABITANT)
      .doc(cohabitantId);
    transaction.set(cohabitantRef, {
      [CohabitantFields.ID]: cohabitantId,
      [CohabitantFields.MEMBERS]: [invitation.createdBy, userId],
    });
    transaction.update(inviterDoc.ref, {
      [AccountFields.COHABITANT_ID]: cohabitantId,
    });
    transaction.update(accountDoc.ref, {
      [AccountFields.COHABITANT_ID]: cohabitantId,
    });
    transaction.update(invitationRef, {
      [InvitationFields.COHABITANT_ID]: cohabitantId,
    });

    return {cohabitantId, joined: true, userName: account.userName};
  });
}

/**
 * 参加者以外のメンバー全員へ、参加を知らせる通知を送る
 *
 * 発行者は共有した時点ではグループに何も起きないため、相手が参加したことを
 * 通知で知らせる。すでに同じ招待から参加しているメンバーにも同様に知らせる。
 * @param {string} cohabitantId 参加したグループのID
 * @param {string} joinerId 参加者のユーザーID
 * @param {string | undefined} joinerName 参加者の表示名
 * @param {NotificationSender} send 送信処理（テスト用に差し替え可能）
 * @return {Promise<NotifyResult | null>} 配信結果
 */
export async function notifyCohabitantJoined(
  cohabitantId: string,
  joinerId: string,
  joinerName: string | undefined,
  send?: NotificationSender
): Promise<NotifyResult | null> {
  const displayName = joinerName ?? "新しいメンバー";
  return await notifyOtherCohabitants(
    cohabitantId,
    joinerId,
    {
      title: `${displayName}がグループに参加しました`,
      body: "これから一緒に家事を管理できます",
    },
    send
  );
}
