import * as logger from "firebase-functions/logger";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {
  isValidNotificationData,
  notifyOtherCohabitants,
} from "./models/CohabitantNotifier";
import {appCheckOptions} from "./appCheckOptions";

interface NotifyCohabitantsRequest {
  cohabitantId: string;
  title: string;
  body: string;
  /** 端末側で通知の種類を判定するための付加情報（任意、値は文字列のみ） */
  data?: unknown;
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
    const {cohabitantId, title, body, data} = request.data;

    if (!cohabitantId || !title || !body) {
      logger.error("Invalid argument: Missing required parameters.", {
        data: request.data,
      });
      throw new HttpsError(
        "invalid-argument",
        "The function must be called with 'cohabitantId', 'title', and " +
        "'body' arguments."
      );
    }

    if (data !== undefined && !isValidNotificationData(data)) {
      logger.error("Invalid argument: 'data' must be a string map.", {
        data: request.data,
      });
      throw new HttpsError(
        "invalid-argument",
        "'data' must be an object whose values are all strings."
      );
    }

    try {
      const result = await notifyOtherCohabitants(
        cohabitantId,
        senderId,
        data === undefined ? {title, body} : {title, body, data}
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
