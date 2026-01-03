import {getFirestore} from "firebase-admin/firestore";
import {getAuth} from "firebase-admin/auth";
import {FirestoreCollections} from "../../src/models/FirestoreCollections";

/**
 * Accountドキュメントが削除されていることを確認（ポーリング方式）
 * @param {string} userId - 確認するユーザーID
 * @param {number} timeoutMs - タイムアウト時間（ミリ秒）
 * @return {Promise<void>}
 */
export async function expectAccountNotExists(
  userId: string,
  timeoutMs = 5000
): Promise<void> {
  const db = getFirestore();
  const startTime = Date.now();

  while (Date.now() - startTime < timeoutMs) {
    const snapshot = await db
      .collection(FirestoreCollections.ACCOUNT)
      .where("id", "==", userId)
      .get();

    if (snapshot.empty) {
      return; // 削除された
    }

    await new Promise((resolve) => setTimeout(resolve, 100)); // 100ms待機
  }

  // タイムアウト
  throw new Error(
    `Account for user ${userId} still exists after ${timeoutMs}ms`
  );
}

/**
 * Cohabitantドキュメントが存在しないことを確認（ポーリング方式）
 * @param {string} cohabitantId - CohabitantドキュメントのID
 * @param {number} timeoutMs - タイムアウト時間（ミリ秒）
 * @return {Promise<void>}
 */
export async function expectCohabitantNotExists(
  cohabitantId: string,
  timeoutMs = 5000
): Promise<void> {
  const db = getFirestore();
  const startTime = Date.now();

  while (Date.now() - startTime < timeoutMs) {
    const doc = await db
      .collection(FirestoreCollections.COHABITANT)
      .doc(cohabitantId)
      .get();

    if (!doc.exists) {
      return; // 削除された
    }

    await new Promise((resolve) => setTimeout(resolve, 100)); // 100ms待機
  }

  // タイムアウト
  throw new Error(
    `Cohabitant ${cohabitantId} still exists after ${timeoutMs}ms`
  );
}

/**
 * Cohabitantのメンバーリストを確認（ポーリング方式）
 * @param {string} cohabitantId - CohabitantドキュメントのID
 * @param {string[]} expectedMembers - 期待されるメンバーIDの配列
 * @param {number} timeoutMs - タイムアウト時間（ミリ秒）
 * @return {Promise<void>}
 */
export async function expectCohabitantMembers(
  cohabitantId: string,
  expectedMembers: string[],
  timeoutMs = 5000
): Promise<void> {
  const db = getFirestore();
  const startTime = Date.now();

  while (Date.now() - startTime < timeoutMs) {
    const doc = await db
      .collection(FirestoreCollections.COHABITANT)
      .doc(cohabitantId)
      .get();

    if (doc.exists) {
      const data = doc.data();
      const members = data?.members || [];

      // メンバーリストが一致したら成功
      const sortedMembers = JSON.stringify(members.sort());
      const sortedExpected = JSON.stringify(expectedMembers.sort());
      if (sortedMembers === sortedExpected) {
        return;
      }
    }

    await new Promise((resolve) => setTimeout(resolve, 100)); // 100ms待機
  }

  // タイムアウト
  const errorMsg = `Cohabitant ${cohabitantId} members did not match ` +
    `expected after ${timeoutMs}ms`;
  throw new Error(errorMsg);
}

/**
 * サブコレクションが空であることを確認（ポーリング方式）
 * @param {string} cohabitantId - CohabitantドキュメントのID
 * @param {string} subcollection - サブコレクション名
 * @param {number} timeoutMs - タイムアウト時間（ミリ秒）
 * @return {Promise<void>}
 */
export async function expectSubcollectionEmpty(
  cohabitantId: string,
  subcollection: string,
  timeoutMs = 5000
): Promise<void> {
  const db = getFirestore();
  const path = FirestoreCollections.getCohabitantSubcollection(
    cohabitantId,
    subcollection
  );
  const startTime = Date.now();

  while (Date.now() - startTime < timeoutMs) {
    const snapshot = await db.collection(path).get();

    if (snapshot.empty) {
      return; // 空になった
    }

    await new Promise((resolve) => setTimeout(resolve, 100)); // 100ms待機
  }

  // タイムアウト
  const errorMsg = `Subcollection ${subcollection} for ${cohabitantId} ` +
    `is not empty after ${timeoutMs}ms`;
  throw new Error(errorMsg);
}

/**
 * Firebase Authユーザーが存在しないことを確認
 * @param {string} userId - 確認するユーザーID
 * @return {Promise<void>}
 */
export async function expectAuthUserNotExists(userId: string): Promise<void> {
  const auth = getAuth();
  try {
    await auth.getUser(userId);
    throw new Error(`Auth user ${userId} still exists`);
  } catch (error: any) {
    if (error.code !== "auth/user-not-found") {
      throw error;
    }
  }
}
