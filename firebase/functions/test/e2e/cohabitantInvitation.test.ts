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
  issueInvitation,
  joinCohabitantByInvitation,
} from "../../src/models/InvitationManager";

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

    it("グループ未所属なら本人のみのグループを作成して招待を発行する", async () => {
      // Arrange
      const userId = `invite-solo-${testCounter}`;
      const now = new Date("2026-09-01T00:00:00.000Z");
      await createTestUser(userId, `${userId}@example.com`);
      await createTestAccount(userId);

      // Act
      const actual = await issueInvitation(userId, now);

      // Assert: グループが作られ、Accountにも紐づく
      await expectCohabitantMembers(actual.cohabitantId, [userId]);
      expect(await fetchCohabitantId(userId)).toBe(actual.cohabitantId);
    });

    it("作成したグループにはクライアントが参照するidフィールドが入る", async () => {
      // Arrange: iOSはid == cohabitantIdでリッスンするため必須
      const userId = `invite-solo-id-${testCounter}`;
      await createTestUser(userId, `${userId}@example.com`);
      await createTestAccount(userId);

      // Act
      const actual = await issueInvitation(userId, new Date());

      // Assert
      const db = getFirestore();
      const snapshot = await db
        .collection(FirestoreCollections.COHABITANT)
        .doc(actual.cohabitantId)
        .get();
      expect(snapshot.data()?.["id"]).toBe(actual.cohabitantId);
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
      expect(actual).toBe(cohabitantId);
      await expectCohabitantMembers(cohabitantId, [ownerId, joinerId]);
      expect(await fetchCohabitantId(joinerId)).toBe(cohabitantId);
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

      // Assert
      expect(actual).toBe(cohabitantId);
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
});
