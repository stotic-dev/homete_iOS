import * as logger from "firebase-functions/logger";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {FirestoreCollections} from "./FirestoreCollections";
import {HouseworkRetention, HouseworkFields} from "./HouseworkRetention";

/** 1バッチで書き込む最大件数（Firestoreのバッチ上限は500） */
const BATCH_SIZE = 500;

/**
 * 同居人グループの家事データのexpiredAtを、ページングしながら一括で再計算する
 *
 * 差分がないドキュメントはスキップするため、同じプランで繰り返し呼んでも
 * 2回目以降は書き込みが発生しない（冪等）。
 * @param {string} cohabitantId 対象の同居人グループID
 * @param {boolean} isGroupPremium グループがプレミアムかどうか
 * @param {Date} executedAt 再計算を実行した日時
 * @return {Promise<number>} 実際に更新した件数
 */
export async function updateHouseworkExpiredAt(
  cohabitantId: string,
  isGroupPremium: boolean,
  executedAt: Date
): Promise<number> {
  const db = getFirestore();
  const collectionRef = db
    .collection(FirestoreCollections.COHABITANT)
    .doc(cohabitantId)
    .collection(FirestoreCollections.HOUSEWORKS);

  let lastDocumentId: string | null = null;
  let updatedCount = 0;

  for (;;) {
    let query = collectionRef.orderBy("__name__").limit(BATCH_SIZE);
    if (lastDocumentId) {
      query = query.startAfter(lastDocumentId);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const indexedDate = (
        data["indexedDate"]?.["value"] as Timestamp | undefined
      )?.toDate();
      if (!indexedDate) {
        logger.warn("Skipped a housework without indexedDate.", {
          cohabitantId,
          documentId: doc.id,
        });
        continue;
      }

      const expiredAt = HouseworkRetention.calcExpiredAt(
        isGroupPremium,
        indexedDate,
        executedAt
      );
      const currentExpiredAt = (
        data[HouseworkFields.EXPIRED_AT] as Timestamp | undefined
      )?.toDate();

      // 差分がないドキュメントは書き込みコストを避けるためスキップする
      if (
        currentExpiredAt &&
        currentExpiredAt.getTime() === expiredAt.getTime()
      ) {
        continue;
      }

      batch.update(doc.ref, {
        [HouseworkFields.EXPIRED_AT]: Timestamp.fromDate(expiredAt),
      });
      batchCount += 1;
    }

    if (batchCount > 0) {
      await batch.commit();
      updatedCount += batchCount;
    }

    if (snapshot.size < BATCH_SIZE) {
      break;
    }
    lastDocumentId = snapshot.docs[snapshot.docs.length - 1].id;
  }

  return updatedCount;
}
