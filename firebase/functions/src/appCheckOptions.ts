import {CallableOptions} from "firebase-functions/v2/https";

/**
 * Callable関数に共通で適用するApp Checkの設定。
 *
 * Firestore側も適用済みにしてあるので、関数側も揃えて強制する。未リリースで
 * 締め出す既存ユーザーがいないため、モニタリング期間は挟んでいない。
 *
 * 背景は doc/adr/0014-firebase-app-check.md を参照。
 */
export const appCheckOptions: CallableOptions = {
  enforceAppCheck: true,
};
