import * as logger from "firebase-functions/logger";
import {getMessaging, MulticastMessage} from "firebase-admin/messaging";
import {FirestoreHelper} from "./FirestoreHelper";

/** 画面に表示する通知の内容 */
export interface AlertNotification {
    title: string;
    body: string;
    /**
     * 端末側で通知の種類を判定するための付加情報（任意）
     *
     * 指定した場合はNotification Service Extensionを起動させるため
     * `mutable-content`を付けて送る。FCMのdataは文字列の値しか持てない。
     */
    data?: Record<string, string>;
}

/**
 * 画面に表示しない通知（サイレント通知）の内容
 *
 * 受け取った端末のアプリをバックグラウンドで起こし、dataを渡すためだけに使う。
 * OSの判断で配信が遅れたり間引かれたりするため、届かなくても困らない用途に限る。
 */
export interface SilentNotification {
    silent: true;
    /** 端末側で通知の種類を判定するための付加情報。FCMのdataは文字列の値しか持てない */
    data: Record<string, string>;
}

/** 通知の内容 */
export type CohabitantNotification = AlertNotification | SilentNotification;

/**
 * サイレント通知かを判定する
 * @param {CohabitantNotification} notification 判定する通知
 * @return {boolean} サイレント通知ならtrue
 */
export function isSilentNotification(
  notification: CohabitantNotification
): notification is SilentNotification {
  return "silent" in notification && notification.silent;
}

/** dataに載せられるキーの上限（ペイロードの肥大化を防ぐ） */
const MAX_DATA_KEYS = 10;

/**
 * dataが「文字列の値だけを持つオブジェクト」かを判定する
 *
 * FCMのdataは文字列の値しか受け付けないため、送信前に弾く。
 * @param {unknown} data 検証する値
 * @return {boolean} 送信できる形式ならtrue
 */
export function isValidNotificationData(
  data: unknown
): data is Record<string, string> {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return false;
  }
  const entries = Object.entries(data);
  return entries.length <= MAX_DATA_KEYS &&
    entries.every(([, value]) => typeof value === "string");
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
 * FCMへ送るマルチキャストメッセージを組み立てる
 *
 * - 表示する通知: dataがあるものだけ`mutable-content`を付ける。iOSはこのフラグが無いと
 *   Notification Service Extensionを起動しないため、端末側で通知の種類を見て
 *   処理したい通知に限って付与する。
 * - サイレント通知: `notification`を付けず`content-available`だけを付ける。
 *   APNsの規約に従い、push typeは`background`、優先度は`5`で送る。
 * @param {string[]} tokens 送信先のFCMトークン
 * @param {CohabitantNotification} notification 通知内容
 * @return {MulticastMessage} 送信するメッセージ
 */
export function buildMulticastMessage(
  tokens: string[],
  notification: CohabitantNotification
): MulticastMessage {
  if (isSilentNotification(notification)) {
    return {
      tokens,
      data: notification.data,
      apns: {
        headers: {
          "apns-push-type": "background",
          "apns-priority": "5",
        },
        payload: {
          aps: {contentAvailable: true},
        },
      },
    };
  }

  const message: MulticastMessage = {
    notification: {
      title: notification.title,
      body: notification.body,
    },
    tokens,
  };

  if (!notification.data) {
    return message;
  }

  return {
    ...message,
    data: notification.data,
    apns: {
      payload: {
        aps: {mutableContent: true},
      },
    },
  };
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
  const batchResponse = await getMessaging().sendEachForMulticast(
    buildMulticastMessage(tokens, notification)
  );

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
