import * as functions from "firebase-functions/v1";
import * as logger from "firebase-functions/logger";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {FirestoreHelper} from "./models/FirestoreHelper";
import {CohabitantFields} from "./models/Cohabitant";

export const deleteuserdata = functions.auth.user().onDelete(async (user) => {
  const userId = user.uid;
  logger.info(`Starting user data deletion for: ${userId}`);

  const firestoreHelper = new FirestoreHelper();
  const db = getFirestore();

  try {
    // Step 1: Accountドキュメントの検索と取得
    const result = await firestoreHelper.findAccountByUserId(userId);

    if (!result) {
      logger.warn(`Account not found for user: ${userId}`);
      return;
    }

    const {snapshot: accountSnapshot, account} = result;
    const linkedCohabitantId = account.cohabitantId;

    logger.info(`Account found. Linked cohabitant: ${linkedCohabitantId}`);

    // Step 2: Accountドキュメントの削除
    await accountSnapshot.ref.delete();
    logger.info(`Account removed for: ${userId}`);

    // Step 3: Cohabitantグループの処理
    if (!linkedCohabitantId) {
      logger.info(`User ${userId} has no linked cohabitant group.`);
      return;
    }

    const cohabitantResult = await firestoreHelper.getCohabitant(
      linkedCohabitantId
    );

    if (!cohabitantResult) {
      logger.warn(`Cohabitant ${linkedCohabitantId} does not exist.`);
      return;
    }

    const {snapshot: cohabitantSnapshot, cohabitant} = cohabitantResult;
    const memberList = cohabitant.members;

    // Step 4: メンバー数に応じた処理
    // メンバーが2人以下の場合はグループごと削除
    if (memberList.length <= 2) {
      // グループ全体を削除
      // Firestoreは親ドキュメントを消してもサブコレクションを消さないため、
      // Cohabitant配下（Houseworks / HouseworkTemplates とそのネスト）を
      // recursiveDeleteでまとめて削除する
      await db.recursiveDelete(cohabitantSnapshot.ref);
      logger.info(
        `Cohabitant group ${linkedCohabitantId} fully removed. ` +
                `Reason: Insufficient members (${memberList.length} members).`
      );
    } else {
      // 3人以上のグループの場合は、メンバーリストから削除のみ
      await cohabitantSnapshot.ref.update({
        [CohabitantFields.MEMBERS]: FieldValue.arrayRemove(userId),
      });
      logger.info(
        `User ${userId} removed from cohabitant ` +
                `${linkedCohabitantId}. ` +
                `Remaining members: ${memberList.length - 1}`
      );
    }
  } catch (err) {
    logger.error("Failed to delete user data:", {err, userId});
    // トリガー関数ではthrowせず、ログに記録するのみ
  }
});
