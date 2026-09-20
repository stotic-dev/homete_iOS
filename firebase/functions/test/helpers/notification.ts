import {
  CohabitantNotification,
  NotificationSender,
} from "../../src/models/CohabitantNotifier";

/** 記録された1回分の送信内容 */
export interface SentNotification {
    tokens: string[];
    notification: CohabitantNotification;
}

/** 送信内容を記録する送信処理と、その記録 */
export interface RecordingSender {
    sender: NotificationSender;
    sent: SentNotification[];
}

/**
 * 送信内容を記録するだけの送信処理を作る
 * Emulator上ではFCMへ送信できないため、配信対象の検証に使う
 * @return {RecordingSender} 送信処理と記録
 */
export function makeRecordingSender(): RecordingSender {
  const sent: SentNotification[] = [];
  const sender: NotificationSender = async (tokens, notification) => {
    sent.push({tokens, notification});
    return {successCount: tokens.length, failureCount: 0};
  };
  return {sender, sent};
}
