import { getFirestore } from "firebase-admin/firestore";
import { FirestoreCollections } from "./FirestoreCollections";
import { Account, AccountFields, AccountConverter } from "./Account";
import { Cohabitant, CohabitantConverter } from "./Cohabitant";

/**
 * Firestoreへのアクセスを型安全に抽象化するヘルパークラス
 */
export class FirestoreHelper {
    private db: FirebaseFirestore.Firestore;

    constructor() {
        this.db = getFirestore();
    }

    /**
     * ユーザーIDからAccountドキュメントを検索
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

        return { snapshot, account };
    }

    /**
     * Cohabitantドキュメントを取得
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

        return { snapshot, cohabitant };
    }

    /**
     * メンバーIDの配列からAccountドキュメントを取得
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
     */
    private chunkArray<T>(array: T[], size: number): T[][] {
        const chunks: T[][] = [];
        for (let i = 0; i < array.length; i += size) {
            chunks.push(array.slice(i, i + size));
        }
        return chunks;
    }
}
