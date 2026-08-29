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
    cohabitantId: string;
    /** 有効期限（epochミリ秒） */
    expiresAt: number;
}

/**
 * 招待トークンを発行する
 *
 * 呼び出し元がまだグループに所属していない場合は、本人のみが所属する
 * グループを新規作成してから招待を発行する。
 * @param {string} userId 発行する本人のユーザーID
 * @param {Date} now 実行日時
 * @return {Promise<IssuedInvitation>} 発行した招待
 */
export async function issueInvitation(
  userId: string,
  now: Date
): Promise<IssuedInvitation> {
  const db = getFirestore();
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

  const accountDoc = accountSnapshot.docs[0];
  const account = AccountConverter.fromFirestoreData(accountDoc.data());
  let cohabitantId = account.cohabitantId;

  // グループ未所属の場合は、招待者ひとりのグループを先に作る
  if (!cohabitantId) {
    cohabitantId = randomUUID();
    await db
      .collection(FirestoreCollections.COHABITANT)
      .doc(cohabitantId)
      .set({
        [CohabitantFields.ID]: cohabitantId,
        [CohabitantFields.MEMBERS]: [userId],
      });
    await accountDoc.ref.update({
      [AccountFields.COHABITANT_ID]: cohabitantId,
    });
  }

  const token = randomUUID();
  const expiresAt = new Date(now.getTime() + INVITATION_EXPIRATION_MS);

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

/**
 * 招待トークンを使ってグループに参加する
 *
 * トークンの検証からメンバー追加・アカウント更新までをトランザクションで行う。
 * すでに同じグループへ参加済みの場合は、リンクの再タップを想定して
 * 書き込みを行わず成功として扱う。
 * @param {string} userId 参加する本人のユーザーID
 * @param {string} token 招待トークン
 * @param {Date} now 実行日時
 * @return {Promise<string>} 参加したグループのID
 */
export async function joinCohabitantByInvitation(
  userId: string,
  token: string,
  now: Date
): Promise<string> {
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

    if (account.cohabitantId) {
      // 同じグループへの再参加は、リンクを再度開いただけなので成功扱いにする
      if (account.cohabitantId === invitation.cohabitantId) {
        return invitation.cohabitantId;
      }

      throw new InvitationError(
        "already-joined",
        `User ${userId} already belongs to another cohabitant group.`
      );
    }

    const cohabitantRef = db
      .collection(FirestoreCollections.COHABITANT)
      .doc(invitation.cohabitantId);
    const cohabitantSnapshot = await transaction.get(cohabitantRef);
    const cohabitant = CohabitantConverter.fromFirestore(cohabitantSnapshot);

    if (!cohabitant) {
      throw new InvitationError(
        "cohabitant-not-found",
        `Cohabitant ${invitation.cohabitantId} was not found.`
      );
    }

    transaction.update(cohabitantRef, {
      [CohabitantFields.MEMBERS]: FieldValue.arrayUnion(userId),
    });
    transaction.update(accountDoc.ref, {
      [AccountFields.COHABITANT_ID]: invitation.cohabitantId,
    });

    return invitation.cohabitantId;
  });
}
