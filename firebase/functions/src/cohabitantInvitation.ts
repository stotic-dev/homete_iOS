import * as logger from "firebase-functions/logger";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {
  InvitationError,
  InvitationErrorCode,
  issueInvitation,
  joinCohabitantByInvitation,
} from "./models/InvitationManager";
import {appCheckOptions} from "./appCheckOptions";

interface JoinCohabitantRequest {
  token: string;
}

/**
 * 招待処理のエラーをHttpsErrorに変換する
 *
 * 標準のエラーコードだけでは、招待固有の失敗（期限切れなど）と
 * 通信起因の失敗（タイムアウト・関数の未デプロイ）を区別できない。
 * 例えば "deadline-exceeded" は期限切れとリクエストのタイムアウトの
 * 両方で返り、"not-found" は関数自体が未デプロイのときにも返る。
 * そのためクライアントが判別できるよう、招待固有のコードを details に載せる。
 * @param {InvitationErrorCode} code 招待処理のエラー種別
 * @param {string} message エラーメッセージ
 * @return {HttpsError} クライアントへ返すエラー
 */
function toHttpsError(
  code: InvitationErrorCode,
  message: string
): HttpsError {
  const details = {invitationErrorCode: code};
  switch (code) {
  case "account-not-found":
  case "invitation-not-found":
  case "cohabitant-not-found":
    return new HttpsError("not-found", message, details);
  case "invitation-expired":
    return new HttpsError("deadline-exceeded", message, details);
  case "already-joined":
    return new HttpsError("failed-precondition", message, details);
  }
}

/**
 * 同居人グループへの招待トークンを発行する
 *
 * 発行者がグループ未所属の場合は、発行者ひとりのグループを新規作成してから
 * 招待を発行する（招待リンク経由でのグループ作成に対応するため）。
 */
export const issuecohabitantinvitation = onCall(
  appCheckOptions,
  async (request: { auth?: { uid: string } }) => {
    if (!request.auth) {
      logger.error("Authentication error: User is not authenticated.");
      throw new HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const userId = request.auth.uid;

    try {
      const invitation = await issueInvitation(userId, new Date());

      logger.info("Issued cohabitant invitation.", {
        userId,
        cohabitantId: invitation.cohabitantId,
      });

      return invitation;
    } catch (error) {
      if (error instanceof InvitationError) {
        logger.error("Failed to issue invitation.", {
          userId,
          code: error.code,
        });
        throw toHttpsError(error.code, error.message);
      }
      throw error;
    }
  }
);

/**
 * 招待トークンを使って同居人グループに参加する
 *
 * すでに別のグループへ参加しているユーザーは参加できない
 * （既存グループの家事データを失わせないため）。
 */
export const joincohabitant = onCall(
  appCheckOptions,
  async (request: {
    data: JoinCohabitantRequest;
    auth?: { uid: string };
  }) => {
    if (!request.auth) {
      logger.error("Authentication error: User is not authenticated.");
      throw new HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const userId = request.auth.uid;
    const {token} = request.data;

    if (!token) {
      logger.error("Invalid argument: Missing 'token'.", {userId});
      throw new HttpsError(
        "invalid-argument",
        "The function must be called with a 'token' argument."
      );
    }

    try {
      const cohabitantId = await joinCohabitantByInvitation(
        userId,
        token,
        new Date()
      );

      logger.info("Joined cohabitant group by invitation.", {
        userId,
        cohabitantId,
      });

      return {cohabitantId};
    } catch (error) {
      if (error instanceof InvitationError) {
        logger.error("Failed to join cohabitant group.", {
          userId,
          code: error.code,
        });
        throw toHttpsError(error.code, error.message);
      }
      throw error;
    }
  }
);
