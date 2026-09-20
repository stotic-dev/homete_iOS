import * as logger from "firebase-functions/logger";
import {getMessaging} from "firebase-admin/messaging";
import {FirestoreHelper} from "./FirestoreHelper";

/** 通知の内容 */
export interface CohabitantNotification {
    title: string;
    body: string;
}

/** 送信処理の結果 */
export interface SendResult {
    successCount: number;
    failureCount: number;
}

/**
 * FCMトークンの一覧へ通知を送る関数
 *
 * 既定では`getMessaging().sendEachForMulticast`を使う。
 * Emulator上ではFCMへ送信できないため、テストでは差し替える。
 */
export type NotificationSender = (
    tokens: string[],
    notification: CohabitantNotification
) => Promise<SendResult>;

/** 通知配信の結果 */
export interface NotifyResult {
    /** 通知を配信した相手のFCMトークン（配信対象が居ない場合は空） */
    tokens: string[];
    successCount: number;
    failureCount: number;
}

/**
 * 既定の送信処理（FCMへ実際に送信する）
 * @param {string[]} tokens 送信先のFCMトークン
 * @param {CohabitantNotification} notification 通知内容
 * @return {Promise<SendResult>} 送信結果
 */
async function defaultSender(
  tokens: string[],
  notification: CohabitantNotification
): Promise<SendResult> {
  const batchResponse = await getMessaging().sendEachForMulticast({
    notification: {
      title: notification.title,
      body: notification.body,
    },
    tokens,
  });

  if (batchResponse.failureCount > 0) {
    const failedTokens = tokens.filter(
      (_, index) => !batchResponse.responses[index].success
    );
    logger.warn("List of tokens that caused failures:", {failedTokens});
  }

  return {
    successCount: batchResponse.successCount,
    failureCount: batchResponse.failureCount,
  };
}

/**
 * グループの本人以外のメンバー全員へ通知を送る
 *
 * FCMトークンを持たないメンバーは対象外とする。
 * グループが存在しない場合は呼び出し側で扱いを決められるようnullを返す。
 * @param {string} cohabitantId 通知先のグループID
 * @param {string} senderId 通知の起点となった本人のユーザーID（配信対象から除く）
 * @param {CohabitantNotification} notification 通知内容
 * @param {NotificationSender} send 送信処理（テスト用に差し替え可能）
 * @return {Promise<NotifyResult | null>} 配信結果。グループが無い場合はnull
 */
export async function notifyOtherCohabitants(
  cohabitantId: string,
  senderId: string,
  notification: CohabitantNotification,
  send: NotificationSender = defaultSender
): Promise<NotifyResult | null> {
  const firestoreHelper = new FirestoreHelper();
  const cohabitantResult = await firestoreHelper.getCohabitant(cohabitantId);

  if (!cohabitantResult) {
    return null;
  }

  const recipientIds = cohabitantResult.cohabitant.members.filter(
    (memberId) => memberId !== senderId
  );

  if (recipientIds.length === 0) {
    logger.info("No other members in the group to notify.", {cohabitantId});
    return {tokens: [], successCount: 0, failureCount: 0};
  }

  const accounts = await firestoreHelper.getAccountsByUserIds(recipientIds);
  const tokens = accounts
    .map((account) => account.fcmToken)
    .filter((token): token is string => !!token);

  if (tokens.length === 0) {
    logger.info("No FCM tokens found for any of the recipients.", {
      cohabitantId,
    });
    return {tokens: [], successCount: 0, failureCount: 0};
  }

  const result = await send(tokens, notification);
  logger.info("Successfully sent messages.", {
    cohabitantId,
    successCount: result.successCount,
    failureCount: result.failureCount,
  });

  return {tokens, ...result};
}
