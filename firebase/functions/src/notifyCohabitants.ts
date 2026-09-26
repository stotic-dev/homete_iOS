import * as logger from "firebase-functions/logger";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {
  CohabitantNotification,
  isValidNotificationData,
  notifyOtherCohabitants,
} from "./models/CohabitantNotifier";
import {appCheckOptions} from "./appCheckOptions";

interface NotifyCohabitantsRequest {
  cohabitantId: string;
  /** 通知のタイトル（サイレント通知では不要） */
  title?: string;
  /** 通知の本文（サイレント通知では不要） */
  body?: string;
  /**
   * 端末側で通知の種類を判定するための付加情報（値は文字列のみ）
   *
   * 表示する通知では任意、サイレント通知では必須。
   */
  data?: unknown;
  /**
   * trueなら画面に表示しないサイレント通知として送る（任意）
   *
   * 省略時は表示する通知として扱う。古いアプリは指定しないため、既定値を変えないこと。
   */
  silent?: boolean;
}

/**
 * リクエストから送信する通知を組み立てる
 * @param {NotifyCohabitantsRequest} request 呼び出し時のリクエスト
 * @return {CohabitantNotification} 送信する通知
 */
function makeNotification(
  request: NotifyCohabitantsRequest
): CohabitantNotification {
  const {title, body, data, silent} = request;

  if (data !== undefined && !isValidNotificationData(data)) {
    logger.error("Invalid argument: 'data' must be a string map.", {
      data: request,
    });
    throw new HttpsError(
      "invalid-argument",
      "'data' must be an object whose values are all strings."
    );
  }

  if (silent === true) {
    // サイレント通知はdataを届けることだけが目的なので、dataが無ければ送る意味がない
    if (data === undefined || Object.keys(data).length === 0) {
      logger.error("Invalid argument: Silent notification requires data.", {
        data: request,
      });
      throw new HttpsError(
        "invalid-argument",
        "A silent notification must be called with non-empty 'data'."
      );
    }
    return {silent: true, data};
  }

  if (!title || !body) {
    logger.error("Invalid argument: Missing required parameters.", {
      data: request,
    });
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with 'cohabitantId', 'title', and " +
      "'body' arguments."
    );
  }
  return data === undefined ? {title, body} : {title, body, data};
}

export const notifyothercohabitants = onCall(
  appCheckOptions,
  async (request: {
    data: NotifyCohabitantsRequest;
    auth?: { uid: string };
  }) => {
    logger.info("Executing notifyothercohabitants function", {
      data: request.data,
    });

    if (!request.auth) {
      logger.error("Authentication error: User is not authenticated.");
      throw new HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const senderId = request.auth.uid;
    const {cohabitantId} = request.data;

    if (!cohabitantId) {
      logger.error("Invalid argument: Missing required parameters.", {
        data: request.data,
      });
      throw new HttpsError(
        "invalid-argument",
        "The function must be called with 'cohabitantId'."
      );
    }

    const notification = makeNotification(request.data);

    try {
      const result = await notifyOtherCohabitants(
        cohabitantId,
        senderId,
        notification
      );

      if (!result) {
        logger.error(`Cohabitant group with id ${cohabitantId} not found.`);
        throw new HttpsError(
          "not-found",
          `Cohabitant group with id ${cohabitantId} not found.`
        );
      }

      if (result.tokens.length === 0) {
        return {success: true, message: "No recipient tokens found."};
      }

      return {
        success: true,
        message: `Notifications sent to ${result.successCount} devices.`,
      };
    } catch (error) {
      logger.error("An unexpected error occurred:", {error});
      throw new HttpsError(
        "internal",
        "An unexpected error occurred.",
        error
      );
    }
  }
);
