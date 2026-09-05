import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import {FirestoreCollections} from "../../src/models/FirestoreCollections";
import {Account} from "../../src/models/Account";
import {Cohabitant} from "../../src/models/Cohabitant";
import {
  houseworksPath,
  houseworkTemplatesPath,
  houseworkTemplateDaysPath,
  houseworkTemplateEditorsPath,
} from "./clientCollections";

export interface TestUser {
    uid: string;
    email: string;
}

/**
 * テストユーザーを作成
 * @param {string} uid - ユーザーID
 * @param {string} email - メールアドレス
 * @return {Promise<TestUser>} 作成されたテストユーザー
 */
export async function createTestUser(
  uid: string,
  email: string
): Promise<TestUser> {
  const auth = getAuth();
  await auth.createUser({uid, email});
  return {uid, email};
}

/**
 * テスト用Accountドキュメントを作成
 * プロダクションコードのAccountモデルを使用
 * @param {string} userId - ユーザーID
 * @param {string} cohabitantId - CohabitantドキュメントのID（オプション）
 * @param {string} fcmToken - FCMトークン（オプション）
 * @param {boolean} isPremium - プレミアム加入状態（省略時はfalse）
 * @return {Promise<void>}
 */
export async function createTestAccount(
  userId: string,
  cohabitantId?: string,
  fcmToken?: string,
  isPremium = false
): Promise<void> {
  const db = getFirestore();

  // Accountモデルに準拠したデータを作成
  const account: Account = {
    id: userId,
    cohabitantId,
    fcmToken,
    isPremium,
  };

  // undefinedフィールドを除外してFirestoreに保存
  const accountData = removeUndefinedFields(account);

  await db.collection(FirestoreCollections.ACCOUNT).add(accountData);
}

/**
 * テストCohabitantドキュメントを作成
 * プロダクションコードのCohabitantモデルを使用
 * @param {string} cohabitantId - CohabitantドキュメントのID
 * @param {string[]} members - メンバーIDの配列
 * @return {Promise<void>}
 */
export async function createTestCohabitant(
  cohabitantId: string,
  members: string[]
): Promise<void> {
  const db = getFirestore();

  // Cohabitantモデルに準拠したデータを作成
  const cohabitant: Cohabitant = {
    id: cohabitantId,
    members,
  };

  await db
    .collection(FirestoreCollections.COHABITANT)
    .doc(cohabitantId)
    .set(cohabitant);
}

/**
 * Cohabitantのサブコレクションにテストデータを追加
 * Houseworkモデルはまだ定義されていないため、汎用的なRecord型を使用
 * @param {string} cohabitantId - CohabitantドキュメントのID
 * @param {string} houseworkId - HouseworkドキュメントのID
 * @param {Record<string, any>} data - 保存するデータ
 * @return {Promise<void>}
 */
export async function createTestHousework(
  cohabitantId: string,
  houseworkId: string,
  data: Record<string, any>
): Promise<void> {
  const db = getFirestore();
  await db.collection(houseworksPath(cohabitantId)).doc(houseworkId).set(data);
}

/**
 * 家事テンプレートのテストデータを追加
 * メタドキュメントに加えて、ネストしたDays/Editorsサブコレクションも作成する
 * @param {string} cohabitantId - CohabitantドキュメントのID
 * @param {string} templateId - テンプレートドキュメントのID
 * @return {Promise<void>}
 */
export async function createTestHouseworkTemplate(
  cohabitantId: string,
  templateId: string
): Promise<void> {
  const db = getFirestore();

  await db
    .collection(houseworkTemplatesPath(cohabitantId))
    .doc(templateId)
    .set({templateId, name: `Template ${templateId}`, version: 0});

  await db
    .collection(houseworkTemplateDaysPath(cohabitantId, templateId))
    .doc("1")
    .set({dayOfWeek: 1, items: []});

  await db
    .collection(houseworkTemplateEditorsPath(cohabitantId, templateId))
    .doc("editor-1")
    .set({userId: "editor-1"});
}

/**
 * undefinedフィールドを除外するヘルパー関数
 * @param {T} obj - 処理するオブジェクト
 * @return {Partial<T>} undefinedフィールドを除外したオブジェクト
 * @template T
 */
function removeUndefinedFields<T extends Record<string, any>>(
  obj: T
): Partial<T> {
  const result: Partial<T> = {};
  for (const key in obj) {
    if (obj[key] !== undefined) {
      result[key] = obj[key];
    }
  }
  return result;
}
