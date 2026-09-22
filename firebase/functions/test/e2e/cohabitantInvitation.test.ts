import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {
  createTestUser,
  createTestAccount,
  createTestCohabitant,
} from "../helpers/testData";
import {expectCohabitantMembers} from "../helpers/assertions";
import {FirestoreCollections} from "../../src/models/FirestoreCollections";
import {
  INVITATION_EXPIRATION_MS,
  InvitationError,
  fetchInvitation,
  issueInvitation,
  joinCohabitantByInvitation,
  notifyCohabitantJoined,
} from "../../src/models/InvitationManager";
import {makeRecordingSender} from "../helpers/notification";

describe("cohabitantInvitation E2E Tests", () => {
  let testCounter = 0;

  beforeEach(() => {
    testCounter++;
  });

  /**
   * 指定ユーザーのAccountドキュメントのcohabitantIdを取得する
   * @param {string} userId ユーザーID
   * @return {Promise<string | undefined>} 保存されているcohabitantId
   */
  async function fetchCohabitantId(
    userId: string
  ): Promise<string | undefined> {
    const db = getFirestore();
    const snapshot = await db
      .collection(FirestoreCollections.ACCOUNT)
      .where("id", "==", userId)
      .limit(1)
      .get();
    return snapshot.docs[0]?.data()?.["cohabitantId"] as string | undefined;
  }

  /**
   * 指定ユーザーのAccountドキュメント参照を取得する
   * @param {string} userId ユーザーID
   * @return {Promise<FirebaseFirestore.DocumentReference | undefined>} 参照
   */
  async function fetchAccountRef(
    userId: string
  ): Promise<FirebaseFirestore.DocumentReference | undefined> {
    const db = getFirestore();
    const snapshot = await db
      .collection(FirestoreCollections.ACCOUNT)
      .where("id", "==", userId)
      .limit(1)
      .get();
    return snapshot.docs[0]?.ref;
  }

  /**
   * 招待ドキュメントの有効期限を書き換える
   * @param {string} token 招待トークン
   * @param {Date} expiresAt 上書きする有効期限
   * @return {Promise<void>}
   */
  async function overwriteExpiresAt(
    token: string,
    expiresAt: Date
  ): Promise<void> {
    const db = getFirestore();
    await db
      .collection(FirestoreCollections.INVITATION)
      .doc(token)
      .update({expiresAt: Timestamp.fromDate(expiresAt)});
  }

  describe("issueInvitation", () => {
    it("グループ所属済みなら所属グループの招待が発行される", async () => {
      // Arrange
      const userId = `invite-owner-${testCounter}`;
      const cohabitantId = `invite-cohabitant-${testCounter}`;
      const now = new Date("2026-09-01T00:00:00.000Z");
      await createTestUser(userId, `${userId}@example.com`);
      await createTestAccount(userId, cohabitantId);
      await createTestCohabitant(cohabitantId, [userId]);

      // Act
      const actual = await issueInvitation(userId, now);

      // Assert
      expect(actual.cohabitantId).toBe(cohabitantId);
      expect(actual.expiresAt).toBe(
        now.getTime() + INVITATION_EXPIRATION_MS
      );
      expect(actual.token).not.toBe("");
    });

    it("グループ未所属ならグループを作らずcohabitantIdがnullの招待を発行する", async () => {
      // Arrange
      const userId = `invite-solo-${testCounter}`;
      const now = new Date("2026-09-01T00:00:00.000Z");
      await createTestUser(userId, `${userId}@example.com`);
      await createTestAccount(userId);

      // Act
      const actual = await issueInvitation(userId, now);

      // Assert: 発行時点ではグループは作られず、Accountも未所属のまま
      expect(actual.cohabitantId).toBeNull();
      expect(await fetchCohabitantId(userId)).toBeUndefined();
      const db = getFirestore();
      const snapshot = await db
        .collection(FirestoreCollections.INVITATION)
        .doc(actual.token)
        .get();
      expect(snapshot.data()?.["cohabitantId"]).toBeNull();
      expect(snapshot.data()?.["createdBy"]).toBe(userId);
    });

    it("Accountが存在しない場合はaccount-not-foundになる", async () => {
      // Arrange
      const userId = `invite-no-account-${testCounter}`;

      // Act & Assert
      await expect(
        issueInvitation(userId, new Date())
      ).rejects.toMatchObject({code: "account-not-found"});
    });
  });

  describe("fetchInvitation", () => {
    it("招待者名と招待先グループを取得できる", async () => {
      // Arrange
      const ownerId = `fetch-owner-${testCounter}`;
      const cohabitantId = `fetch-cohabitant-${testCounter}`;
      const now = new Date("2026-09-01T00:00:00.000Z");
      await createTestUser(ownerId, `${ownerId}@example.com`);
      await createTestAccount(ownerId, cohabitantId, undefined, false, "たろう");
      await createTestCohabitant(cohabitantId, [ownerId]);
      const invitation = await issueInvitation(ownerId, now);

      // Act
      const actual = await fetchInvitation(invitation.token, now);

      // Assert
      expect(actual).toEqual({
        inviterName: "たろう",
        cohabitantId,
        expiresAt: invitation.expiresAt,
      });
    });

    it("招待者が名前未設定・グループ未所属ならどちらもnullになる", async () => {
      // Arrange
      const ownerId = `fetch-anonymous-${testCounter}`;
      const now = new Date("2026-09-01T00:00:00.000Z");
      await createTestUser(ownerId, `${ownerId}@example.com`);
      await createTestAccount(ownerId);
      const invitation = await issueInvitation(ownerId, now);

      // Act
      const actual = await fetchInvitation(invitation.token, now);

      // Assert
      expect(actual.inviterName).toBeNull();
      expect(actual.cohabitantId).toBeNull();
    });

    it("発行後に招待者がグループへ所属した場合はそのグループを返す", async () => {
      // Arrange
      const ownerId = `fetch-late-owner-${testCounter}`;
      const cohabitantId = `fetch-late-cohabitant-${testCounter}`;
      const now = new Date("2026-09-01T00:00:00.000Z");
      await createTestUser(ownerId, `${ownerId}@example.com`);
      await createTestAccount(ownerId);
      const invitation = await issueInvitation(ownerId, now);
      const ownerRef = await fetchAccountRef(ownerId);
      await ownerRef?.update({cohabitantId});
      await createTestCohabitant(cohabitantId, [ownerId]);

      // Act
      const actual = await fetchInvitation(invitation.token, now);

      // Assert
      expect(actual.cohabitantId).toBe(cohabitantId);
    });

    it("存在しないトークンはinvitation-not-foundになる", async () => {
      // Act & Assert
      await expect(
        fetchInvitation(`missing-token-${testCounter}`, new Date())
      ).rejects.toMatchObject({code: "invitation-not-found"});
    });

    it("期限切れの招待はinvitation-expiredになる", async () => {
      // Arrange
      const ownerId = `fetch-expired-owner-${testCounter}`;
      const now = new Date("2026-09-01T00:00:00.000Z");
      await createTestUser(ownerId, `${ownerId}@example.com`);
      await createTestAccount(ownerId);
      const invitation = await issueInvitation(ownerId, now);
      await overwriteExpiresAt(invitation.token, now);

      // Act & Assert
      const error = await fetchInvitation(invitation.token, now).catch(
        (e) => e
      );
      expect(error).toBeInstanceOf(InvitationError);
      expect(error.code).toBe("invitation-expired");
    });
  });

  describe("joinCohabitantByInvitation", () => {
    it("招待トークンでグループに参加できる", async () => {
      // Arrange
      const ownerId = `join-owner-${testCounter}`;
      const joinerId = `join-user-${testCounter}`;
      const cohabitantId = `join-cohabitant-${testCounter}`;
      await createTestUser(ownerId, `${ownerId}@example.com`);
      await createTestUser(joinerId, `${joinerId}@example.com`);
      await createTestAccount(ownerId, cohabitantId);
      await createTestAccount(joinerId);
      await createTestCohabitant(cohabitantId, [ownerId]);
      const invitation = await issueInvitation(ownerId, new Date());

      // Act
      const actual = await joinCohabitantByInvitation(
        joinerId,
        invitation.token,
        new Date()
      );

      // Assert
      expect(actual).toEqual({cohabitantId, joined: true});
      await expectCohabitantMembers(cohabitantId, [ownerId, joinerId]);
      expect(await fetchCohabitantId(joinerId)).toBe(cohabitantId);
    });

    it("発行者が未所属なら参加時に発行者と参加者のグループが作られる", async () => {
      // Arrange
      const ownerId = `lazy-owner-${testCounter}`;
      const joinerId = `lazy-joiner-${testCounter}`;
      await createTestUser(ownerId, `${ownerId}@example.com`);
      await createTestUser(joinerId, `${joinerId}@example.com`);
      await createTestAccount(ownerId);
      await createTestAccount(joinerId);
      const invitation = await issueInvitation(ownerId, new Date());

      // Act
      const actual = await joinCohabitantByInvitation(
        joinerId,
        invitation.token,
        new Date()
      );

      // Assert: 2人のグループが作られ、双方のAccountと招待に紐づく
      const {cohabitantId} = actual;
      expect(actual.joined).toBe(true);
      await expectCohabitantMembers(cohabitantId, [ownerId, joinerId]);
      expect(await fetchCohabitantId(ownerId)).toBe(cohabitantId);
      expect(await fetchCohabitantId(joinerId)).toBe(cohabitantId);
      const db = getFirestore();
      const cohabitantSnapshot = await db
        .collection(FirestoreCollections.COHABITANT)
        .doc(cohabitantId)
        .get();
      // iOSはid == cohabitantIdでリッスンするため必須
      expect(cohabitantSnapshot.data()?.["id"]).toBe(cohabitantId);
      const invitationSnapshot = await db
        .collection(FirestoreCollections.INVITATION)
        .doc(invitation.token)
        .get();
      expect(invitationSnapshot.data()?.["cohabitantId"]).toBe(cohabitantId);
    });

    it("参加時に作られたグループへ同じ招待で2人目も参加できる", async () => {
      // Arrange
      const ownerId = `lazy-multi-owner-${testCounter}`;
      const firstId = `lazy-multi-first-${testCounter}`;
      const secondId = `lazy-multi-second-${testCounter}`;
      await createTestAccount(ownerId);
      await createTestAccount(firstId);
      await createTestAccount(secondId);
      const invitation = await issueInvitation(ownerId, new Date());

      // Act
      const created = await joinCohabitantByInvitation(
        firstId,
        invitation.token,
        new Date()
      );
      const joined = await joinCohabitantByInvitation(
        secondId,
        invitation.token,
        new Date()
      );

      // Assert
      expect(joined.cohabitantId).toBe(created.cohabitantId);
      await expectCohabitantMembers(
        created.cohabitantId,
        [ownerId, firstId, secondId]
      );
    });

    it("発行後に発行者が別経路でグループに参加していれば、そのグループへ参加する", async () => {
      // Arrange: 招待発行 → 発行者がP2P登録でグループ作成 → 参加者がリンクを開く
      const ownerId = `late-owner-${testCounter}`;
      const joinerId = `late-joiner-${testCounter}`;
      const cohabitantId = `late-cohabitant-${testCounter}`;
      await createTestAccount(ownerId);
      await createTestAccount(joinerId);
      const invitation = await issueInvitation(ownerId, new Date());
      await createTestCohabitant(cohabitantId, [ownerId]);
      await (await fetchAccountRef(ownerId))?.update({cohabitantId});

      // Act
      const actual = await joinCohabitantByInvitation(
        joinerId,
        invitation.token,
        new Date()
      );

      // Assert
      expect(actual.cohabitantId).toBe(cohabitantId);
      await expectCohabitantMembers(cohabitantId, [ownerId, joinerId]);
    });

    it("発行者が退会済みで参加先を作れない場合はcohabitant-not-foundになる", async () => {
      // Arrange
      const ownerId = `gone-owner-${testCounter}`;
      const joinerId = `gone-joiner-${testCounter}`;
      await createTestAccount(ownerId);
      await createTestAccount(joinerId);
      const invitation = await issueInvitation(ownerId, new Date());
      await (await fetchAccountRef(ownerId))?.delete();

      // Act & Assert
      await expect(
        joinCohabitantByInvitation(joinerId, invitation.token, new Date())
      ).rejects.toMatchObject({code: "cohabitant-not-found"});
      expect(await fetchCohabitantId(joinerId)).toBeUndefined();
    });

    it("同じ招待で複数人が参加できる", async () => {
      // Arrange
      const ownerId = `multi-owner-${testCounter}`;
      const firstId = `multi-first-${testCounter}`;
      const secondId = `multi-second-${testCounter}`;
      const cohabitantId = `multi-cohabitant-${testCounter}`;
      await createTestAccount(ownerId, cohabitantId);
      await createTestAccount(firstId);
      await createTestAccount(secondId);
      await createTestCohabitant(cohabitantId, [ownerId]);
      const invitation = await issueInvitation(ownerId, new Date());

      // Act
      await joinCohabitantByInvitation(firstId, invitation.token, new Date());
      await joinCohabitantByInvitation(secondId, invitation.token, new Date());

      // Assert
      await expectCohabitantMembers(
        cohabitantId,
        [ownerId, firstId, secondId]
      );
    });

    it("同じグループへの再参加は書き込みせず成功する（冪等）", async () => {
      // Arrange: リンクを再度タップした場合を想定する
      const ownerId = `idempotent-owner-${testCounter}`;
      const joinerId = `idempotent-joiner-${testCounter}`;
      const cohabitantId = `idempotent-cohabitant-${testCounter}`;
      await createTestAccount(ownerId, cohabitantId);
      await createTestAccount(joinerId);
      await createTestCohabitant(cohabitantId, [ownerId]);
      const invitation = await issueInvitation(ownerId, new Date());
      await joinCohabitantByInvitation(joinerId, invitation.token, new Date());

      // Act
      const actual = await joinCohabitantByInvitation(
        joinerId,
        invitation.token,
        new Date()
      );

      // Assert: メンバーは増えず、参加通知の対象にもならない
      expect(actual).toEqual({cohabitantId, joined: false});
      await expectCohabitantMembers(cohabitantId, [ownerId, joinerId]);
    });

    it("別グループに参加済みのユーザーはalready-joinedで弾かれる", async () => {
      // Arrange
      const ownerId = `other-owner-${testCounter}`;
      const joinerId = `other-joiner-${testCounter}`;
      const cohabitantId = `other-cohabitant-${testCounter}`;
      const joinedCohabitantId = `other-joined-cohabitant-${testCounter}`;
      await createTestAccount(ownerId, cohabitantId);
      await createTestAccount(joinerId, joinedCohabitantId);
      await createTestCohabitant(cohabitantId, [ownerId]);
      await createTestCohabitant(joinedCohabitantId, [joinerId]);
      const invitation = await issueInvitation(ownerId, new Date());

      // Act & Assert
      await expect(
        joinCohabitantByInvitation(joinerId, invitation.token, new Date())
      ).rejects.toMatchObject({code: "already-joined"});

      // 参加先グループのメンバーは増えない
      await expectCohabitantMembers(cohabitantId, [ownerId]);
      expect(await fetchCohabitantId(joinerId)).toBe(joinedCohabitantId);
    });

    it("有効期限切れの招待はinvitation-expiredになる", async () => {
      // Arrange
      const ownerId = `expired-owner-${testCounter}`;
      const joinerId = `expired-joiner-${testCounter}`;
      const cohabitantId = `expired-cohabitant-${testCounter}`;
      await createTestAccount(ownerId, cohabitantId);
      await createTestAccount(joinerId);
      await createTestCohabitant(cohabitantId, [ownerId]);
      const invitation = await issueInvitation(ownerId, new Date());
      await overwriteExpiresAt(
        invitation.token,
        new Date("2020-01-01T00:00:00.000Z")
      );

      // Act & Assert
      await expect(
        joinCohabitantByInvitation(joinerId, invitation.token, new Date())
      ).rejects.toMatchObject({code: "invitation-expired"});
      await expectCohabitantMembers(cohabitantId, [ownerId]);
    });

    it("参加結果には通知に使う参加者の表示名が含まれる", async () => {
      // Arrange
      const ownerId = `named-owner-${testCounter}`;
      const joinerId = `named-joiner-${testCounter}`;
      const cohabitantId = `named-cohabitant-${testCounter}`;
      await createTestAccount(ownerId, cohabitantId);
      await createTestAccount(joinerId, undefined, undefined, false, "花子");
      await createTestCohabitant(cohabitantId, [ownerId]);
      const invitation = await issueInvitation(ownerId, new Date());

      // Act
      const actual = await joinCohabitantByInvitation(
        joinerId,
        invitation.token,
        new Date()
      );

      // Assert
      expect(actual).toEqual({cohabitantId, joined: true, userName: "花子"});
    });

    it("存在しないトークンはinvitation-not-foundになる", async () => {
      // Arrange
      const joinerId = `unknown-token-joiner-${testCounter}`;
      await createTestAccount(joinerId);

      // Act & Assert
      await expect(
        joinCohabitantByInvitation(joinerId, "unknown-token", new Date())
      ).rejects.toBeInstanceOf(InvitationError);
    });
  });

  describe("notifyCohabitantJoined", () => {
    it("発行者と既に参加済みのメンバー全員に参加通知が送られ、参加者本人には送られない", async () => {
      // Arrange: 発行者 → 1人目が参加済み → 2人目が参加
      const ownerId = `notify-join-owner-${testCounter}`;
      const firstId = `notify-join-first-${testCounter}`;
      const secondId = `notify-join-second-${testCounter}`;
      await createTestAccount(ownerId, undefined, "token-owner");
      await createTestAccount(firstId, undefined, "token-first");
      await createTestAccount(
        secondId,
        undefined,
        "token-second",
        false,
        "太郎"
      );
      const invitation = await issueInvitation(ownerId, new Date());
      await joinCohabitantByInvitation(firstId, invitation.token, new Date());
      const result = await joinCohabitantByInvitation(
        secondId,
        invitation.token,
        new Date()
      );
      const {sender, sent} = makeRecordingSender();

      // Act
      await notifyCohabitantJoined(
        result.cohabitantId,
        secondId,
        result.userName,
        sender
      );

      // Assert
      expect(sent).toHaveLength(1);
      expect(sent[0].tokens).toHaveLength(2);
      expect(sent[0].tokens).toEqual(
        expect.arrayContaining(["token-owner", "token-first"])
      );
      expect(sent[0].notification.title).toBe("太郎がグループに参加しました");
    });

    it("参加者の表示名が無い場合は汎用的な文言で通知する", async () => {
      // Arrange
      const ownerId = `notify-noname-owner-${testCounter}`;
      const joinerId = `notify-noname-joiner-${testCounter}`;
      const cohabitantId = `notify-noname-cohabitant-${testCounter}`;
      await createTestAccount(ownerId, cohabitantId, "token-owner");
      await createTestAccount(joinerId);
      await createTestCohabitant(cohabitantId, [ownerId, joinerId]);
      const {sender, sent} = makeRecordingSender();

      // Act
      await notifyCohabitantJoined(cohabitantId, joinerId, undefined, sender);

      // Assert
      expect(sent).toHaveLength(1);
      expect(sent[0].tokens).toEqual(["token-owner"]);
      expect(sent[0].notification.title).toBe(
        "新しいメンバーがグループに参加しました"
      );
    });
  });
});
