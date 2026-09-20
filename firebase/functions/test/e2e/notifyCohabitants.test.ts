import {
  createTestAccount,
  createTestCohabitant,
} from "../helpers/testData";
import {makeRecordingSender} from "../helpers/notification";
import {
  CohabitantNotification,
  notifyOtherCohabitants,
} from "../../src/models/CohabitantNotifier";

describe("CohabitantNotifier E2E Tests", () => {
  let testCounter = 0;

  beforeEach(() => {
    testCounter++;
  });

  const notification: CohabitantNotification = {
    title: "title",
    body: "body",
  };

  it("本人以外のメンバー全員のFCMトークンへ通知が送られる", async () => {
    // Arrange
    const senderId = `notify-sender-${testCounter}`;
    const firstId = `notify-first-${testCounter}`;
    const secondId = `notify-second-${testCounter}`;
    const cohabitantId = `notify-cohabitant-${testCounter}`;
    await createTestAccount(senderId, cohabitantId, "token-sender");
    await createTestAccount(firstId, cohabitantId, "token-first");
    await createTestAccount(secondId, cohabitantId, "token-second");
    await createTestCohabitant(cohabitantId, [senderId, firstId, secondId]);
    const {sender, sent} = makeRecordingSender();

    // Act
    const actual = await notifyOtherCohabitants(
      cohabitantId,
      senderId,
      notification,
      sender
    );

    // Assert
    expect(actual).toEqual({
      tokens: expect.arrayContaining(["token-first", "token-second"]),
      successCount: 2,
      failureCount: 0,
    });
    expect(sent).toHaveLength(1);
    expect(sent[0].tokens).toHaveLength(2);
    expect(sent[0].tokens).not.toContain("token-sender");
    expect(sent[0].notification).toEqual(notification);
  });

  it("FCMトークンを持たないメンバーは配信対象から除かれる", async () => {
    // Arrange
    const senderId = `notify-notoken-sender-${testCounter}`;
    const withTokenId = `notify-notoken-with-${testCounter}`;
    const withoutTokenId = `notify-notoken-without-${testCounter}`;
    const cohabitantId = `notify-notoken-cohabitant-${testCounter}`;
    await createTestAccount(senderId, cohabitantId, "token-sender");
    await createTestAccount(withTokenId, cohabitantId, "token-with");
    await createTestAccount(withoutTokenId, cohabitantId);
    await createTestCohabitant(
      cohabitantId,
      [senderId, withTokenId, withoutTokenId]
    );
    const {sender, sent} = makeRecordingSender();

    // Act
    await notifyOtherCohabitants(cohabitantId, senderId, notification, sender);

    // Assert
    expect(sent).toHaveLength(1);
    expect(sent[0].tokens).toEqual(["token-with"]);
  });

  it("本人しか居ないグループでは送信せずに空の結果を返す", async () => {
    // Arrange
    const senderId = `notify-alone-sender-${testCounter}`;
    const cohabitantId = `notify-alone-cohabitant-${testCounter}`;
    await createTestAccount(senderId, cohabitantId, "token-sender");
    await createTestCohabitant(cohabitantId, [senderId]);
    const {sender, sent} = makeRecordingSender();

    // Act
    const actual = await notifyOtherCohabitants(
      cohabitantId,
      senderId,
      notification,
      sender
    );

    // Assert
    expect(actual).toEqual({tokens: [], successCount: 0, failureCount: 0});
    expect(sent).toHaveLength(0);
  });

  it("グループが存在しない場合はnullを返す", async () => {
    // Arrange
    const {sender, sent} = makeRecordingSender();

    // Act
    const actual = await notifyOtherCohabitants(
      `notify-missing-${testCounter}`,
      "someone",
      notification,
      sender
    );

    // Assert
    expect(actual).toBeNull();
    expect(sent).toHaveLength(0);
  });
});
