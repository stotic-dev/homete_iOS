import {CallableOptions} from "firebase-functions/v2/https";

/**
 * Callable関数に共通で適用するApp Checkの設定。
 *
 * 現在はモニタリング期間中のため強制しない。Firebaseコンソールのメトリクスで
 * 正規アプリからのリクエストが100%検証済みとして計上されることを確認できたら
 * `enforceAppCheck` を true に切り替える。
 *
 * 背景と切り替え手順は doc/adr/0014-firebase-app-check.md を参照。
 */
export const appCheckOptions: CallableOptions = {
  enforceAppCheck: false,
};
