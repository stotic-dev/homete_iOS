import * as logger from "firebase-functions/logger";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {
  currentProjectId,
  isStgProject,
  revokeRefreshTokens,
} from "./models/DebugAuthTokenRevoker";
import {appCheckOptions} from "./appCheckOptions";

/**
 * 呼び出し元自身のリフレッシュトークンを失効させる（STG限定のデバッグ用）
 *
 * トークン失効による自動サインアウトはクライアント側で再現手段が無いため、
 * アプリのデバッグメニューから意図的にその状態を作れるようにするためのもの。
 * 本番で誤って呼ばれても動かないよう、STGプロジェクト以外では拒否する。
 *
 * 失効対象は`request.auth`のユーザー自身に限定し、引数でユーザーIDを受け取らない。
 * 万一の踏み台化を防ぐため、他人をサインアウトさせる余地を作らない。
 */
export const debugrevokerefreshtokens = onCall(
  appCheckOptions,
  async (request: { auth?: { uid: string } }) => {
    const projectId = currentProjectId();

    if (!isStgProject(projectId)) {
      logger.error("Permission denied: not the stg project.", {projectId});
      throw new HttpsError(
        "permission-denied",
        "This function is available only on the stg project."
      );
    }

    if (!request.auth) {
      logger.error("Authentication error: User is not authenticated.");
      throw new HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const callerId = request.auth.uid;
    const revokedAt = await revokeRefreshTokens(callerId);

    logger.info("Revoked refresh tokens for debugging.", {
      callerId,
      revokedAt,
    });

    return {revokedAt};
  }
);
