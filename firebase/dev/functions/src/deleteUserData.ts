import * as functions from "firebase-functions/v1";
import * as logger from "firebase-functions/logger";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { FirestoreCollections } from "./models/FirestoreCollections";

export const deleteuserdata = functions.auth.user().onDelete(async (user) => {
    const userId = user.uid;
    logger.info(`Starting user data deletion for: ${userId}`);

    const db = getFirestore();

    try {
        // Step 1: Accountドキュメントの検索と取得
        const accountSnapshot = await db
            .collection(FirestoreCollections.ACCOUNT)
            .where("id", "==", userId)
            .limit(1)
            .get();

        if (accountSnapshot.empty) {
            logger.warn(`Account not found for user: ${userId}`);
            return;
        }

        const accountDoc = accountSnapshot.docs[0];
        const accountInfo = accountDoc.data();
        const linkedCohabitantId = accountInfo.cohabitantId;

        logger.info(`Account found. Linked cohabitant: ${linkedCohabitantId}`);

        // Step 2: Accountドキュメントの削除
        await accountDoc.ref.delete();
        logger.info(`Account removed for: ${userId}`);

        // Step 3: Cohabitantグループの処理
        if (!linkedCohabitantId) {
            logger.info(`User ${userId} has no linked cohabitant group.`);
            return;
        }

        const cohabitantRef = db
            .collection(FirestoreCollections.COHABITANT)
            .doc(linkedCohabitantId);
        const cohabitantSnapshot = await cohabitantRef.get();

        if (!cohabitantSnapshot.exists) {
            logger.warn(`Cohabitant ${linkedCohabitantId} does not exist.`);
            return;
        }

        const cohabitantInfo = cohabitantSnapshot.data();
        const memberList = cohabitantInfo?.members || [];

        // Step 4: メンバー数に応じた処理
        // メンバーが2人以下の場合はグループごと削除
        if (memberList.length <= 2) {
            // グループ全体を削除
            await removeCohabitantSubcollections(db, linkedCohabitantId);
            await cohabitantRef.delete();
            logger.info(
                `Cohabitant group ${linkedCohabitantId} fully removed. ` +
                `Reason: Insufficient members (${memberList.length} members).`
            );
        } else {
            // 3人以上のグループの場合は、メンバーリストから削除のみ
            await cohabitantRef.update({
                members: FieldValue.arrayRemove(userId),
            });
            logger.info(
                `User ${userId} removed from cohabitant ${linkedCohabitantId}. ` +
                `Remaining members: ${memberList.length - 1}`
            );
        }
    } catch (err) {
        logger.error("Failed to delete user data:", { err, userId });
        // トリガー関数ではthrowせず、ログに記録するのみ
    }
});

/**
 * Cohabitantのサブコレクションを削除
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
