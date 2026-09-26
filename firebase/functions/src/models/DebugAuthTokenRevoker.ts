import {getAuth} from "firebase-admin/auth";

/**
 * STG（開発）プロジェクトのID。
 *
 * プロジェクトIDは `homete-ios-dev` が本番、`homete-ios-dev-e3ef7` がSTGという
 * 紛らわしい命名になっているので、判定は必ずこの定数を使う。
 */
export const STG_PROJECT_ID = "homete-ios-dev-e3ef7";

/**
 * 実行中のプロジェクトがSTGかどうかを返す
 * @param {string | undefined} projectId 実行中のプロジェクトID
 * @return {boolean} STGなら`true`
 */
export function isStgProject(projectId: string | undefined): boolean {
  return projectId === STG_PROJECT_ID;
}

/**
 * 実行中のプロジェクトIDを環境変数から取得する
 *
 * Cloud Functionsのランタイムとエミュレーターのどちらでも `GCLOUD_PROJECT` が入る。
 * 取得できない場合は`undefined`を返し、呼び出し側でSTG以外として扱わせる。
 * @return {string | undefined} プロジェクトID
 */
export function currentProjectId(): string | undefined {
  return process.env["GCLOUD_PROJECT"];
}

/**
 * 指定ユーザーのリフレッシュトークンを失効させる
 *
 * 失効させるとIDトークンの更新が失敗するようになり、クライアントのFirebase Authは
 * 「ログイン情報が無効」と判断して自動でサインアウトする。この状態を意図的に作るのが目的。
 * @param {string} uid 失効させるユーザーのID
 * @return {Promise<string | undefined>} 失効の基準時刻（`tokensValidAfterTime`）
 */
export async function revokeRefreshTokens(
  uid: string
): Promise<string | undefined> {
  const auth = getAuth();
  await auth.revokeRefreshTokens(uid);
  const user = await auth.getUser(uid);
  return user.tokensValidAfterTime;
}
