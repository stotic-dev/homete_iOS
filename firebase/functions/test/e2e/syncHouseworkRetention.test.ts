import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {
  createTestUser,
  createTestAccount,
  createTestCohabitant,
  createTestHousework,
} from "../helpers/testData";
import {houseworksPath} from "../helpers/clientCollections";
import {
  updateHouseworkExpiredAt,
} from "../../src/models/HouseworkRetentionUpdater";
import {HouseworkRetention} from "../../src/models/HouseworkRetention";

describe("syncHouseworkRetention E2E Tests", () => {
  let testCounter = 0;

  beforeEach(() => {
    testCounter++;
  });

  /**
   * 指定した家事ドキュメントのexpiredAtを取得する
   * @param {string} cohabitantId CohabitantドキュメントのID
   * @param {string} houseworkId 家事ドキュメントのID
   * @return {Promise<Date | undefined>} 保存されているexpiredAt
   */
  async function fetchExpiredAt(
    cohabitantId: string,
    houseworkId: string
  ): Promise<Date | undefined> {
    const db = getFirestore();
    const snapshot = await db
      .collection(houseworksPath(cohabitantId))
      .doc(houseworkId)
      .get();
    return (snapshot.data()?.["expiredAt"] as Timestamp | undefined)?.toDate();
  }

  describe("calcExpiredAt", () => {
    it("プレミアムでは家事の日付を起点に100年後になる", () => {
      // Arrange
      const indexedDate = new Date("2026-08-11T00:00:00.000Z");
      const executedAt = new Date("2026-09-01T00:00:00.000Z");

      // Act
      const actual = HouseworkRetention.calcExpiredAt(
        true,
        indexedDate,
        executedAt
      );

      // Assert
      expect(actual).toEqual(new Date("2126-08-11T00:00:00.000Z"));
    });

    it("無料では解約日を起点に1年後になる", () => {
      // Arrange: 家事の日付ではなく実行日が起点になることを確認する
      const indexedDate = new Date("2020-01-01T00:00:00.000Z");
      const executedAt = new Date("2026-09-01T00:00:00.000Z");

      // Act
      const actual = HouseworkRetention.calcExpiredAt(
        false,
        indexedDate,
        executedAt
      );

      // Assert
      expect(actual).toEqual(new Date("2027-09-01T00:00:00.000Z"));
    });
  });

  describe("updateHouseworkExpiredAt", () => {
    it("プレミアムのグループでは家事の日付+100年に延長される", async () => {
      // Arrange
      const cohabitantId = `sync-premium-cohabitant-${testCounter}`;
      const indexedDate = new Date("2026-08-11T00:00:00.000Z");
      const executedAt = new Date("2026-09-01T00:00:00.000Z");
      await createTestHousework(cohabitantId, "housework-1", {
        indexedDate: {value: Timestamp.fromDate(indexedDate)},
        expiredAt: Timestamp.fromDate(new Date("2027-08-11T00:00:00.000Z")),
      });

      // Act
      const updatedCount = await updateHouseworkExpiredAt(
        cohabitantId,
        true,
        executedAt
      );

      // Assert
      expect(updatedCount).toBe(1);
      const actual = await fetchExpiredAt(cohabitantId, "housework-1");
      expect(actual).toEqual(new Date("2126-08-11T00:00:00.000Z"));
    });

    it("無料のグループでは実行日+1年に短縮される", async () => {
      // Arrange
      const cohabitantId = `sync-free-cohabitant-${testCounter}`;
      const indexedDate = new Date("2020-01-01T00:00:00.000Z");
      const executedAt = new Date("2026-09-01T00:00:00.000Z");
      await createTestHousework(cohabitantId, "housework-1", {
        indexedDate: {value: Timestamp.fromDate(indexedDate)},
        expiredAt: Timestamp.fromDate(new Date("2120-01-01T00:00:00.000Z")),
      });

      // Act
      const updatedCount = await updateHouseworkExpiredAt(
        cohabitantId,
        false,
        executedAt
      );

      // Assert: 家事の日付(2020年)起点ではなく実行日起点になり、猶予が残る
      expect(updatedCount).toBe(1);
      const actual = await fetchExpiredAt(cohabitantId, "housework-1");
      expect(actual).toEqual(new Date("2027-09-01T00:00:00.000Z"));
    });

    it("同じプランで再実行しても書き込みが発生しない（冪等）", async () => {
      // Arrange
      const cohabitantId = `sync-idempotent-cohabitant-${testCounter}`;
      const indexedDate = new Date("2026-08-11T00:00:00.000Z");
      const executedAt = new Date("2026-09-01T00:00:00.000Z");
      await createTestHousework(cohabitantId, "housework-1", {
        indexedDate: {value: Timestamp.fromDate(indexedDate)},
      });
      await updateHouseworkExpiredAt(cohabitantId, true, executedAt);

      // Act
      const updatedCount = await updateHouseworkExpiredAt(
        cohabitantId,
        true,
        executedAt
      );

      // Assert
      expect(updatedCount).toBe(0);
      const actual = await fetchExpiredAt(cohabitantId, "housework-1");
      expect(actual).toEqual(new Date("2126-08-11T00:00:00.000Z"));
    });

    it("バッチ上限の500件を超えても全件更新される", async () => {
      // Arrange
      const cohabitantId = `sync-batch-cohabitant-${testCounter}`;
      const indexedDate = new Date("2026-08-11T00:00:00.000Z");
      const executedAt = new Date("2026-09-01T00:00:00.000Z");
      const documentCount = 520;
      const db = getFirestore();
      let writer = db.batch();
      for (let i = 0; i < documentCount; i++) {
        const ref = db
          .collection(houseworksPath(cohabitantId))
          .doc(`housework-${String(i).padStart(4, "0")}`);
        writer.set(ref, {
          indexedDate: {value: Timestamp.fromDate(indexedDate)},
        });
        // Firestoreのバッチ上限に合わせて500件ごとにコミットする
        if ((i + 1) % 500 === 0) {
          await writer.commit();
          writer = db.batch();
        }
      }
      await writer.commit();

      // Act
      const updatedCount = await updateHouseworkExpiredAt(
        cohabitantId,
        true,
        executedAt
      );

      // Assert
      expect(updatedCount).toBe(documentCount);
      const lastExpiredAt = await fetchExpiredAt(
        cohabitantId,
        "housework-0519"
      );
      expect(lastExpiredAt).toEqual(new Date("2126-08-11T00:00:00.000Z"));
    });

    it("indexedDateを持たないドキュメントはスキップされる", async () => {
      // Arrange
      const cohabitantId = `sync-invalid-cohabitant-${testCounter}`;
      const executedAt = new Date("2026-09-01T00:00:00.000Z");
      await createTestHousework(cohabitantId, "housework-1", {
        title: "indexedDateなし",
      });

      // Act
      const updatedCount = await updateHouseworkExpiredAt(
        cohabitantId,
        true,
        executedAt
      );

      // Assert
      expect(updatedCount).toBe(0);
      const actual = await fetchExpiredAt(cohabitantId, "housework-1");
      expect(actual).toBeUndefined();
    });
  });

  describe("グループのプレミアム判定", () => {
    it("1人でもプレミアムならグループ全体がプレミアム扱いになる", async () => {
      // Arrange
      const uid1 = `sync-group-user-1-${testCounter}`;
      const uid2 = `sync-group-user-2-${testCounter}`;
      const user1 = await createTestUser(uid1, `${uid1}@example.com`);
      const user2 = await createTestUser(uid2, `${uid2}@example.com`);
      const cohabitantId = `sync-group-cohabitant-${testCounter}`;
      await createTestCohabitant(cohabitantId, [user1.uid, user2.uid]);
      await createTestAccount(user1.uid, cohabitantId, "token-1", false);
      await createTestAccount(user2.uid, cohabitantId, "token-2", true);

      const {FirestoreHelper} = await import(
        "../../src/models/FirestoreHelper"
      );
      const helper = new FirestoreHelper();

      // Act
      const accounts = await helper.getAccountsByUserIds([
        user1.uid,
        user2.uid,
      ]);

      // Assert
      expect(accounts.some((account) => account.isPremium)).toBe(true);
    });

    it("全員無料ならグループは無料扱いになる", async () => {
      // Arrange
      const uid1 = `sync-free-group-user-1-${testCounter}`;
      const uid2 = `sync-free-group-user-2-${testCounter}`;
      const user1 = await createTestUser(uid1, `${uid1}@example.com`);
      const user2 = await createTestUser(uid2, `${uid2}@example.com`);
      const cohabitantId = `sync-free-group-cohabitant-${testCounter}`;
      await createTestCohabitant(cohabitantId, [user1.uid, user2.uid]);
      await createTestAccount(user1.uid, cohabitantId, "token-1", false);
      await createTestAccount(user2.uid, cohabitantId, "token-2", false);

      const {FirestoreHelper} = await import(
        "../../src/models/FirestoreHelper"
      );
      const helper = new FirestoreHelper();

      // Act
      const accounts = await helper.getAccountsByUserIds([
        user1.uid,
        user2.uid,
      ]);

      // Assert
      expect(accounts.some((account) => account.isPremium)).toBe(false);
    });
  });
});
