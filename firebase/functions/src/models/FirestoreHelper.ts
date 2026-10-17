import {getFirestore} from "firebase-admin/firestore";
import {FirestoreCollections} from "./FirestoreCollections";
import {
  Account,
  AccountFcmTokenFields,
  AccountFields,
  AccountConverter,
} from "./Account";
import {Cohabitant, CohabitantConverter} from "./Cohabitant";

/**
 * Firestoreへのアクセスを型安全に抽象化するヘルパークラス
 */
export class FirestoreHelper {
  private db: FirebaseFirestore.Firestore;

  /**
     * Firestoreインスタンスを初期化
     */
  constructor() {
    this.db = getFirestore();
  }

  /**
     * ユーザーIDからAccountドキュメントを検索
     * @param {string} userId - 検索するユーザーID
     * @return {Promise<{snapshot: FirebaseFirestore.QueryDocumentSnapshot,
     *   account: Account} | null>} スナップショットとAccount、
     *   または見つからない場合はnull
     */
  async findAccountByUserId(
    userId: string
  ): Promise<{
        snapshot: FirebaseFirestore.QueryDocumentSnapshot;
        account: Account;
    } | null> {
    const querySnapshot = await this.db
      .collection(FirestoreCollections.ACCOUNT)
      .where(AccountFields.ID, "==", userId)
      .limit(1)
      .get();

    if (querySnapshot.empty) {
      return null;
    }

    const snapshot = querySnapshot.docs[0];
    const account = AccountConverter.fromFirestoreData(snapshot.data());

    return {snapshot, account};
  }

  /**
     * Cohabitantドキュメントを取得
     * @param {string} cohabitantId - CohabitantドキュメントのID
     * @return {Promise<{snapshot: FirebaseFirestore.DocumentSnapshot,
     *   cohabitant: Cohabitant} | null>} スナップショットとCohabitant、
     *   または見つからない場合はnull
     */
  async getCohabitant(
    cohabitantId: string
  ): Promise<{
        snapshot: FirebaseFirestore.DocumentSnapshot;
        cohabitant: Cohabitant;
    } | null> {
    const snapshot = await this.db
      .collection(FirestoreCollections.COHABITANT)
      .doc(cohabitantId)
      .get();

    const cohabitant = CohabitantConverter.fromFirestore(snapshot);
    if (!cohabitant) {
      return null;
    }

    return {snapshot, cohabitant};
  }

  /**
     * メンバーIDの配列からAccountドキュメントを取得
     * @param {string[]} userIds - 取得するユーザーIDの配列
     * @return {Promise<Account[]>} Accountの配列
     */
  async getAccountsByUserIds(userIds: string[]): Promise<Account[]> {
    if (userIds.length === 0) {
      return [];
    }

    // Firestoreの"in"クエリは最大10件まで
    const chunks = this.chunkArray(userIds, 10);
    const accounts: Account[] = [];

    for (const chunk of chunks) {
      const querySnapshot = await this.db
        .collection(FirestoreCollections.ACCOUNT)
        .where(AccountFields.ID, "in", chunk)
        .get();

      querySnapshot.forEach((doc) => {
        accounts.push(AccountConverter.fromFirestoreData(doc.data()));
      });
    }

    return accounts;
  }

  /**
     * メンバーIDの配列から、通知の送信先になるFCMトークンを取得
     *
     * `Account/{uid}/Private/fcm`を優先し、無いユーザーは旧バージョンのアプリが
     * Accountへ書き込んだ`fcmToken`で補う。トークンを持たないユーザーは含めない。
     * @param {string[]} userIds - 取得するユーザーIDの配列
     * @return {Promise<string[]>} FCMトークンの配列
     */
  async getFcmTokensByUserIds(userIds: string[]): Promise<string[]> {
    if (userIds.length === 0) {
      return [];
    }

    const snapshots = await this.db.getAll(
      ...userIds.map((userId) => this.fcmTokenRef(userId))
    );
    const tokenByUserId = new Map<string, string>();
    snapshots.forEach((snapshot, index) => {
      const token = snapshot.get(AccountFcmTokenFields.TOKEN);
      if (typeof token === "string" && token) {
        tokenByUserId.set(userIds[index], token);
      }
    });

    // 新しいパスにトークンが無いユーザーだけ、旧バージョンのアプリが書いた値を読む
    const legacyUserIds = userIds.filter((id) => !tokenByUserId.has(id));
    const legacyAccounts = await this.getAccountsByUserIds(legacyUserIds);
    legacyAccounts.forEach((account) => {
      if (account.fcmToken) {
        tokenByUserId.set(account.id, account.fcmToken);
      }
    });

    return userIds
      .map((id) => tokenByUserId.get(id))
      .filter((token): token is string => !!token);
  }

  /**
     * FCMトークンを置くドキュメントの参照を取得
     * @param {string} userId - ユーザーID
     * @return {FirebaseFirestore.DocumentReference}
     *   `Account/{uid}/Private/fcm`の参照
     */
  fcmTokenRef(userId: string): FirebaseFirestore.DocumentReference {
    return this.db
      .collection(FirestoreCollections.ACCOUNT)
      .doc(userId)
      .collection(FirestoreCollections.ACCOUNT_PRIVATE)
      .doc(FirestoreCollections.ACCOUNT_PRIVATE_FCM);
  }

  /**
     * 配列を指定サイズのチャンクに分割
     * @template T
     * @param {Array<T>} array - 分割する配列
     * @param {number} size - チャンクのサイズ
     * @return {Array<Array<T>>} チャンクに分割された配列
     */
  private chunkArray<T>(array: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }
}
