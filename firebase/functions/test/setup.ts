import {initializeApp, getApps, deleteApp, App} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

// Emulator接続設定
process.env.FIRESTORE_EMULATOR_HOST = "localhost:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "localhost:9099";

let app: App;

beforeAll(() => {
  // テスト用Firebase Admin初期化
  if (getApps().length === 0) {
    app = initializeApp({projectId: "homete-ios-dev-e3ef7"});
  }
});

afterAll(async () => {
  // クリーンアップ
  if (app) {
    await deleteApp(app);
  }
});

beforeEach(async () => {
  // 各テスト前にFirestoreをクリア（Authはクリアしない）
  await clearFirestore();
});

/**
 * Firestoreのデータをクリアする
 * @return {Promise<void>}
 */
async function clearFirestore() {
  const db = getFirestore();
  const collections = ["Account", "Cohabitant", "Invitation"];

  // サブコレクションが残るとテスト間で状態が混ざるため再帰的に削除する
  for (const collectionName of collections) {
    await db.recursiveDelete(db.collection(collectionName));
  }
}
