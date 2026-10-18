import {getAuth} from "firebase-admin/auth";
import {
  ANONYMOUS_ACCOUNT_RETENTION_DAYS,
  deleteAnonymousUser,
  deleteStaleAnonymousUsers,
} from "../../src/models/AnonymousAccountCleaner";
import {
  createTestAccount,
  createTestCohabitant,
  createTestUser,
} from "../helpers/testData";
import {
  expectAccountNotExists,
  expectAuthUserNotExists,
  expectCohabitantNotExists,
} from "../helpers/assertions";

const MILLISECONDS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * 匿名認証のままのユーザーを作成する（プロバイダ・メールアドレスを持たない）
 * @param {string} uid ユーザーID
 * @return {Promise<void>}
 */
async function createAnonymousUser(uid: string): Promise<void> {
  await getAuth().createUser({uid});
}

/**
 * Appleアカウントと連携済みのユーザーを作成する
 * @param {string} uid ユーザーID
 * @return {Promise<void>}
 */
async function createAppleLinkedUser(uid: string): Promise<void> {
  await getAuth().createUser({uid});
  await getAuth().updateUser(uid, {
    providerToLink: {providerId: "apple.com", uid: `apple-${uid}`},
  });
}

/**
 * 今作ったユーザーが、保持日数を過ぎたとみなされる日時
 * @return {Date} 保持日数より1日先の日時
 */
function afterRetentionPeriod(): Date {
  return new Date(
    Date.now() + (ANONYMOUS_ACCOUNT_RETENTION_DAYS + 1) * MILLISECONDS_PER_DAY
  );
}

describe("AnonymousAccountCleaner E2E Tests", () => {
  let testCounter = 0;

  beforeEach(() => {
    testCounter++;
  });

  describe("deleteStaleAnonymousUsers", () => {
    it("保持日数を過ぎた匿名アカウントを削除し、Account・グループも後片付けされる", async () => {
      // Arrange
      const anonymousUid = `stale-anonymous-${testCounter}`;
      const partnerUid = `stale-partner-${testCounter}`;
      const cohabitantId = `stale-cohabitant-${testCounter}`;
      await createAnonymousUser(anonymousUid);
      await createTestUser(partnerUid, `${partnerUid}@example.com`);
      await createTestCohabitant(cohabitantId, [anonymousUid, partnerUid]);
      await createTestAccount(anonymousUid, cohabitantId);
      await createTestAccount(partnerUid, cohabitantId);

      // Act
      const actual = await deleteStaleAnonymousUsers(afterRetentionPeriod());

      // Assert
      expect(actual).toContain(anonymousUid);
      await expectAuthUserNotExists(anonymousUid);
      await expectAccountNotExists(anonymousUid);
      await expectCohabitantNotExists(cohabitantId);
    });

    it("Appleと連携済みのユーザーは、保持日数を過ぎても削除しない", async () => {
      // Arrange
      const uid = `stale-linked-${testCounter}`;
      await createAppleLinkedUser(uid);

      // Act
      const actual = await deleteStaleAnonymousUsers(afterRetentionPeriod());

      // Assert
      expect(actual).not.toContain(uid);
      await expect(getAuth().getUser(uid)).resolves.toBeDefined();
    });

    it("保持日数を過ぎていない匿名アカウントは削除しない", async () => {
      // Arrange
      const uid = `fresh-anonymous-${testCounter}`;
      await createAnonymousUser(uid);

      // Act
      const actual = await deleteStaleAnonymousUsers(new Date());

      // Assert
      expect(actual).not.toContain(uid);
      await expect(getAuth().getUser(uid)).resolves.toBeDefined();
    });
  });

  describe("deleteAnonymousUser", () => {
    it("匿名のユーザーを削除する", async () => {
      // Arrange
      const uid = `delete-anonymous-${testCounter}`;
      await createAnonymousUser(uid);

      // Act
      const actual = await deleteAnonymousUser(uid);

      // Assert
      expect(actual).toBe(true);
      await expectAuthUserNotExists(uid);
    });

    it("Appleと連携済みのユーザーは削除しない", async () => {
      // Arrange
      const uid = `delete-linked-${testCounter}`;
      await createAppleLinkedUser(uid);

      // Act
      const actual = await deleteAnonymousUser(uid);

      // Assert
      expect(actual).toBe(false);
      await expect(getAuth().getUser(uid)).resolves.toBeDefined();
    });
  });
});
