import * as functions from "firebase-functions/v1";
import * as logger from "firebase-functions/logger";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {FirestoreCollections} from "./models/FirestoreCollections";
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
      await removeCohabitantSubcollections(db, linkedCohabitantId);
      await cohabitantSnapshot.ref.delete();
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

/**
 * Cohabitantのサブコレクションを削除
 * @param {FirebaseFirestore.Firestore} db Firestoreインスタンス
 * @param {string} cohabitantId CohabitantのID
 * @return {Promise<void>}
 */
async function removeCohabitantSubcollections(
  db: FirebaseFirestore.Firestore,
  cohabitantId: string
): Promise<void> {
  const subcollections = [
    FirestoreCollections.HOUSEWORK,
    FirestoreCollections.HOUSEWORK_HISTORY,
  ];

  for (const subcollection of subcollections) {
    const path = FirestoreCollections.getCohabitantSubcollection(
      cohabitantId,
      subcollection
    );
    await batchDeleteCollection(db, path, 500);
  }
}

/**
 * コレクション内のドキュメントをバッチ削除
 * @param {FirebaseFirestore.Firestore} db Firestoreインスタンス
 * @param {string} path コレクションのパス
 * @param {number} limit 一度に削除する上限数
 * @return {Promise<void>}
 */
async function batchDeleteCollection(
  db: FirebaseFirestore.Firestore,
  path: string,
  limit: number
): Promise<void> {
  const collectionRef = db.collection(path);
  const querySnapshot = await collectionRef.limit(limit).get();

  if (querySnapshot.empty) {
    logger.info(`No documents in ${path}`);
    return;
  }

  const batchOperation = db.batch();
  querySnapshot.docs.forEach((document) => {
    batchOperation.delete(document.ref);
  });
  await batchOperation.commit();

  logger.info(`Removed ${querySnapshot.size} documents from ${path}`);

  // 再帰的に残りを削除
  if (querySnapshot.size >= limit) {
    await batchDeleteCollection(db, path, limit);
  }
}
