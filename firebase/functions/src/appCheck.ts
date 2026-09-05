import * as logger from "firebase-functions/logger";
import {CallableOptions} from "firebase-functions/v2/https";

/**
 * Callable関数に共通で適用するApp Checkの設定。
 *
 * 現在はモニタリング期間中のため強制しない。`logAppCheckStatus` が出すログで
 * 正規アプリからのリクエストが100%検証済みになることを確認できたら
 * `enforceAppCheck` を true に切り替える。
 *
 * 背景と切り替え手順は doc/adr/0014-firebase-app-check.md を参照。
 */
export const appCheckOptions: CallableOptions = {
  enforceAppCheck: false,
};

/**
 * App Checkトークンの検証結果をログに出す。
 *
 * Callable関数はApp Checkのメトリクス対象サービスではなく、コンソールで検証状況を
 * 確認できない。またSDKはトークンが不正なときしか警告を出さず、そもそも送られて
 * こなかったケースは無言で通すため、モニタリングには自前のログが要る。
 *
 * @param {string} functionName ログを出す関数名
 * @param {unknown} app 検証済みのApp Checkデータ。未検証ならundefined
 */
export function logAppCheckStatus(
  functionName: string,
  app: unknown
): void {
  logger.info("App Check status", {
    function: functionName,
    // 検証を通ったリクエストにだけrequest.appが入る。
    // 未送信・検証失敗のどちらもundefinedになるため、両者は区別できない。
    verified: app !== undefined,
  });
}
