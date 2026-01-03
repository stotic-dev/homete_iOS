import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getMessaging } from "firebase-admin/messaging";
import { FirestoreHelper } from "./models/FirestoreHelper";

interface NotifyCohabitantsRequest {
  cohabitantId: string;
  title: string;
  body: string;
}

export const notifyothercohabitants = onCall(
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
    const { cohabitantId, title, body } = request.data;

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

    const firestoreHelper = new FirestoreHelper();

    try {
      // 1. Get the cohabitant group document
      const cohabitantResult = await firestoreHelper.getCohabitant(
        cohabitantId
      );

      if (!cohabitantResult) {
        logger.error(`Cohabitant group with id ${cohabitantId} not found.`);
        throw new HttpsError(
          "not-found",
          `Cohabitant group with id ${cohabitantId} not found.`
        );
      }

      const { cohabitant } = cohabitantResult;
      const members = cohabitant.members;

      if (members.length === 0) {
        logger.error(`Cohabitant group ${cohabitantId} has no members.`);
        return { success: true, message: "No members found in the group." };
      }

      // 2. Filter out the sender to get recipient IDs
      const recipientIds = members.filter(
        (memberId: string) => memberId !== senderId
      );

      if (recipientIds.length === 0) {
        logger.info("No other members in the group to notify.");
        return { success: true, message: "No other members to notify." };
      }

      // 3. Get FCM tokens for the recipients
      const accounts = await firestoreHelper.getAccountsByUserIds(recipientIds);
      const tokens: string[] = accounts
        .map((account) => account.fcmToken)
        .filter((token): token is string => !!token);

      if (tokens.length === 0) {
        logger.info("No FCM tokens found for any of the recipients.");
        return { success: true, message: "No recipient tokens found." };
      }

      // 4. Send notifications
      const message = {
        notification: {
          title: title,
          body: body,
        },
        tokens: tokens,
      };

      const batchResponse = await getMessaging().sendEachForMulticast(message);
      logger.info("Successfully sent messages.", {
        successCount: batchResponse.successCount,
        failureCount: batchResponse.failureCount,
      });

      if (batchResponse.failureCount > 0) {
        const failedTokens: string[] = [];
        batchResponse.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens[idx]);
          }
        });
        logger.warn("List of tokens that caused failures:", { failedTokens });
      }

      return {
        success: true,
        message: `Notifications sent to ${batchResponse.successCount} devices.`,
      };
    } catch (error) {
      logger.error("An unexpected error occurred:", { error });
      throw new HttpsError(
        "internal",
        "An unexpected error occurred.",
        error
      );
    }
  }
);
