import * as logger from "firebase-functions/logger";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {
  deleteAnonymousUser,
  deleteStaleAnonymousUsers,
} from "./models/AnonymousAccountCleaner";
import {appCheckOptions} from "./appCheckOptions";

/**
 * 呼び出し元の匿名アカウントを削除する
 *
 * 匿名のアカウントは再認証できないため、最後のサインインから時間がたつと端末からは削除できない
 * （`requires-recent-login`）。退会と、既存のアカウントへの切り替えのときにここから削除する。
 * 削除の対象は`request.auth`のユーザー自身に限り、引数でユーザーIDを受け取らない。
 * Account・グループの後片付けは`deleteuserdata`に任せる。
 */
export const deleteanonymousaccount = onCall(
  appCheckOptions,
  async (request: { auth?: { uid: string } }) => {
    if (!request.auth) {
      logger.error("Authentication error: User is not authenticated.");
      throw new HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const callerId = request.auth.uid;
    const isDeleted = await deleteAnonymousUser(callerId);
    if (!isDeleted) {
      logger.error("Rejected deleting a non-anonymous account.", {callerId});
      throw new HttpsError(
        "failed-precondition",
        "Only anonymous accounts can be deleted with this function."
      );
    }

    logger.info("Deleted anonymous account.", {callerId});
    return {};
  }
);

/**
 * 最後に使われてから30日たった匿名アカウントを、毎日削除する
 *
 * Apple連携の画面で離脱した人の匿名アカウントが、グループのメンバーとして残り続けないようにするため。
 */
export const cleanupanonymousaccounts = onSchedule(
  {schedule: "every day 04:00", timeZone: "Asia/Tokyo"},
  async () => {
    const deletedUserIds = await deleteStaleAnonymousUsers(new Date());
    logger.info("Deleted stale anonymous accounts.", {
      count: deletedUserIds.length,
    });
  }
);
