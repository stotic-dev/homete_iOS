import {getFirestore} from "firebase-admin/firestore";
import {FirestoreCollections} from "./FirestoreCollections";
import {Account, AccountFields, AccountConverter} from "./Account";
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
