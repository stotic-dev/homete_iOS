import {getAuth, UserRecord} from "firebase-admin/auth";

/**
 * 放置された匿名アカウントを残しておく日数。最後に使われてからこの日数を過ぎたら削除する
 */
export const ANONYMOUS_ACCOUNT_RETENTION_DAYS = 30;

const MILLISECONDS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * 匿名認証のまま、どのプロバイダ（Appleなど）とも連携していないユーザーかを返す
 * @param {UserRecord} user 判定するユーザー
 * @return {boolean} 匿名のままなら`true`
 */
export function isAnonymousUser(user: UserRecord): boolean {
  return user.providerData.length === 0 && !user.email && !user.phoneNumber;
}

/**
 * 最後に使われてから保持日数を過ぎた匿名アカウントかを返す
 *
 * 匿名のアカウントはアプリを使い続けてもサインインし直さないため、最後のサインイン日時は作成時のまま動かない。
 * 使っているかどうかはIDトークンを最後に更新した日時（`lastRefreshTime`）で判定し、
 * 記録が無ければ最後のサインイン日時、それも無ければ作成日時で判定する。
 * @param {UserRecord} user 判定するユーザー
 * @param {Date} now 現在日時
 * @return {boolean} 削除する対象なら`true`
 */
export function isStaleAnonymousUser(user: UserRecord, now: Date): boolean {
  if (!isAnonymousUser(user)) {
    return false;
  }

  const lastActiveTime =
    user.metadata.lastRefreshTime ||
    user.metadata.lastSignInTime ||
    user.metadata.creationTime;
  const threshold =
    now.getTime() - ANONYMOUS_ACCOUNT_RETENTION_DAYS * MILLISECONDS_PER_DAY;
  return new Date(lastActiveTime).getTime() < threshold;
}

/**
 * 最後に使われてから保持日数を過ぎた匿名アカウントを削除する
 *
 * Account・グループの後片付けは、Authの削除トリガー（`deleteuserdata`）に任せる。
 * `deleteUsers`でまとめて消すと削除トリガーが呼ばれないため、1件ずつ消す。
 * @param {Date} now 現在日時
 * @return {Promise<string[]>} 削除したユーザーのID
 */
export async function deleteStaleAnonymousUsers(now: Date): Promise<string[]> {
  const auth = getAuth();
  const deletedUserIds: string[] = [];
  let pageToken: string | undefined;

  do {
    const result = await auth.listUsers(1000, pageToken);
    for (const user of result.users) {
      if (!isStaleAnonymousUser(user, now)) {
        continue;
      }
      await auth.deleteUser(user.uid);
      deletedUserIds.push(user.uid);
    }
    pageToken = result.pageToken;
  } while (pageToken);

  return deletedUserIds;
}

/**
 * 匿名のままのユーザーを削除する
 *
 * Appleと連携済みのユーザーは、Appleの再認証とトークンの失効を伴う退会の手順を通すため、ここでは削除しない。
 * @param {string} userId 削除するユーザーのID
 * @return {Promise<boolean>} 削除したら`true`。匿名でなければ削除せず`false`
 */
export async function deleteAnonymousUser(userId: string): Promise<boolean> {
  const auth = getAuth();
  const user = await auth.getUser(userId);
  if (!isAnonymousUser(user)) {
    return false;
  }

  await auth.deleteUser(userId);
  return true;
}
