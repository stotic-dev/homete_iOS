import * as logger from "firebase-functions/logger";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {FirestoreHelper} from "./models/FirestoreHelper";
import {updateHouseworkExpiredAt} from "./models/HouseworkRetentionUpdater";
import {appCheckOptions, logAppCheckStatus} from "./appCheck";

interface SyncHouseworkRetentionRequest {
  cohabitantId: string;
}

/**
 * 同居人グループの家事データの保持期限を現在のプランに合わせて再計算する
 *
 * プレミアム加入時・解約時の双方から呼ばれる。「現在のプランに揃える」処理として
 * 冪等に実装しているため、何度呼んでも結果は変わらない。
 *
 * グループ内に1人でもプレミアム会員がいればグループ全体を無期限保持とする。
 * 家事データはグループの共有物であり、メンバーごとに保持期間を分けると
 * 同じ日の家事の一部だけが消えて貢献度の集計が壊れるため。
 */
export const synchouseworkretention = onCall(
  appCheckOptions,
  async (request: {
    data: SyncHouseworkRetentionRequest;
    auth?: { uid: string };
    app?: { appId: string };
  }) => {
    logAppCheckStatus("synchouseworkretention", request.app);

    if (!request.auth) {
      logger.error("Authentication error: User is not authenticated.");
      throw new HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const callerId = request.auth.uid;
    const {cohabitantId} = request.data;

    if (!cohabitantId) {
      logger.error("Invalid argument: Missing 'cohabitantId'.", {
        data: request.data,
      });
      throw new HttpsError(
        "invalid-argument",
        "The function must be called with a 'cohabitantId' argument."
      );
    }

    const firestoreHelper = new FirestoreHelper();
    const cohabitantResult = await firestoreHelper.getCohabitant(cohabitantId);

    if (!cohabitantResult) {
      logger.error("Cohabitant not found.", {cohabitantId});
      throw new HttpsError("not-found", "The cohabitant group was not found.");
    }

    const members = cohabitantResult.cohabitant.members;

    // 他人のグループのデータを書き換えられないよう、呼び出し元がメンバーか検証する
    if (!members.includes(callerId)) {
      logger.error("Permission denied: caller is not a group member.", {
        cohabitantId,
        callerId,
      });
      throw new HttpsError(
        "permission-denied",
        "The caller does not belong to the cohabitant group."
      );
    }

    const accounts = await firestoreHelper.getAccountsByUserIds(members);
    const isGroupPremium = accounts.some((account) => account.isPremium);
    const executedAt = new Date();

    logger.info("Start syncing housework retention.", {
      cohabitantId,
      isGroupPremium,
      memberCount: members.length,
    });

    const updatedCount = await updateHouseworkExpiredAt(
      cohabitantId,
      isGroupPremium,
      executedAt
    );

    logger.info("Finished syncing housework retention.", {
      cohabitantId,
      isGroupPremium,
      updatedCount,
    });

    return {isGroupPremium, updatedCount};
  }
);
