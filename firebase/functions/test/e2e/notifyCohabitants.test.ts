import {
  createTestAccount,
  createTestCohabitant,
} from "../helpers/testData";
import {makeRecordingSender} from "../helpers/notification";
import {
  buildMulticastMessage,
  CohabitantNotification,
  isValidNotificationData,
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

  it("dataを指定した通知はdataを保ったまま送信処理へ渡される", async () => {
    // Arrange
    const senderId = `notify-data-sender-${testCounter}`;
    const receiverId = `notify-data-receiver-${testCounter}`;
    const cohabitantId = `notify-data-cohabitant-${testCounter}`;
    await createTestAccount(senderId, cohabitantId, "token-sender");
    await createTestAccount(receiverId, cohabitantId, "token-receiver");
    await createTestCohabitant(cohabitantId, [senderId, receiverId]);
    const {sender, sent} = makeRecordingSender();
    const notificationWithData: CohabitantNotification = {
      title: "title",
      body: "body",
      data: {type: "houseworkApproved", houseworkDate: "1767193200"},
    };

    // Act
    await notifyOtherCohabitants(
      cohabitantId,
      senderId,
      notificationWithData,
      sender
    );

    // Assert
    expect(sent).toEqual([
      {tokens: ["token-receiver"], notification: notificationWithData},
    ]);
  });
});

describe("buildMulticastMessage", () => {
  it("dataが無い通知はmutable-contentを付けずに組み立てる", () => {
    // Act
    const actual = buildMulticastMessage(
      ["token"],
      {title: "title", body: "body"}
    );

    // Assert
    expect(actual).toEqual({
      notification: {title: "title", body: "body"},
      tokens: ["token"],
    });
  });

  it("dataがある通知はdataとmutable-contentを付けて組み立てる", () => {
    // Act
    const actual = buildMulticastMessage(
      ["token"],
      {title: "title", body: "body", data: {type: "houseworkApproved"}}
    );

    // Assert
    expect(actual).toEqual({
      notification: {title: "title", body: "body"},
      tokens: ["token"],
      data: {type: "houseworkApproved"},
      apns: {payload: {aps: {mutableContent: true}}},
    });
  });
});

describe("isValidNotificationData", () => {
  it.each([
    ["文字列の値だけを持つオブジェクト", {type: "a", date: "1"}, true],
    ["空のオブジェクト", {}, true],
    ["文字列以外の値を含む", {type: "a", count: 1}, false],
    ["配列", ["a"], false],
    ["null", null, false],
    ["文字列", "a", false],
    [
      "キーが上限を超える",
      Object.fromEntries(
        Array.from({length: 11}, (_, index) => [`key${index}`, "v"])
      ),
      false,
    ],
  ])("%sの場合は%sを返す", (_, data, expected) => {
    // Act
    const actual = isValidNotificationData(data);

    // Assert
    expect(actual).toBe(expected);
  });
});
