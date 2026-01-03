import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { FirestoreCollections } from "./models/FirestoreCollections";

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

    const db = getFirestore();

    try {
      // 1. Get the cohabitant group document
      const cohabitantDocRef = db
        .collection(FirestoreCollections.COHABITANT)
        .doc(cohabitantId);
      const cohabitantDoc = await cohabitantDocRef.get();

      if (!cohabitantDoc.exists) {
        logger.error(`Cohabitant group with id ${cohabitantId} not found.`);
        throw new HttpsError(
          "not-found",
          `Cohabitant group with id ${cohabitantId} not found.`
        );
      }

      const cohabitantData = cohabitantDoc.data();
      if (!cohabitantData || !cohabitantData.members) {
        logger.error(`Cohabitant group ${cohabitantId} has no members field.`);
        return { success: true, message: "No members found in the group." };
      }

      // 2. Filter out the sender to get recipient IDs
      const recipientIds = cohabitantData.members.filter(
        (memberId: string) => memberId !== senderId
      );

      if (recipientIds.length === 0) {
        logger.info("No other members in the group to notify.");
        return { success: true, message: "No other members to notify." };
      }

      // 3. Get FCM tokens for the recipients
      const tokens: string[] = [];
      const accountsQuery = await db
        .collection(FirestoreCollections.ACCOUNT)
        .where("id", "in", recipientIds)
        .get();

      accountsQuery.forEach((doc) => {
        const accountData = doc.data();
        if (accountData && accountData.fcmToken) {
          tokens.push(accountData.fcmToken);
        }
      });

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
