import {getAuth} from "firebase-admin/auth";
import {createTestUser} from "../helpers/testData";
import {
  STG_PROJECT_ID,
  isStgProject,
  revokeRefreshTokens,
} from "../../src/models/DebugAuthTokenRevoker";

describe("DebugAuthTokenRevoker E2E Tests", () => {
  let testCounter = 0;

  beforeEach(() => {
    testCounter++;
  });

  describe("isStgProject", () => {
    it("STGプロジェクトなら許可する", () => {
      // Act
      const actual = isStgProject(STG_PROJECT_ID);

      // Assert
      expect(actual).toBe(true);
    });

    it("本番プロジェクトは拒否する", () => {
      // Act
      const actual = isStgProject("homete-ios-dev");

      // Assert
      expect(actual).toBe(false);
    });

    it("プロジェクトIDが取得できない場合は拒否する", () => {
      // Act
      const actual = isStgProject(undefined);

      // Assert
      expect(actual).toBe(false);
    });
  });

  describe("revokeRefreshTokens", () => {
    it("失効させると、以降の基準時刻が失効前より後になる", async () => {
      // Arrange
      const uid = `revoke-target-${testCounter}`;
      await createTestUser(uid, `${uid}@example.com`);
      const before = await getAuth().getUser(uid);

      // Act
      const actual = await revokeRefreshTokens(uid);

      // Assert: 失効前は基準時刻が無い（または失効後より過去）ことを確認する
      expect(actual).toBeDefined();
      const revokedAt = new Date(actual ?? 0).getTime();
      const beforeAt = before.tokensValidAfterTime ?
        new Date(before.tokensValidAfterTime).getTime() :
        0;
      expect(revokedAt).toBeGreaterThan(beforeAt);
    });
  });
});
