/**
 * Accountドキュメントの構造（Functionsで使用するプロパティのみ）
 */
export interface Account {
    id: string;
    cohabitantId?: string;
    fcmToken?: string;
}

/**
 * Accountドキュメントのフィールド名定数
 */
export class AccountFields {
    static readonly ID = "id";
    static readonly COHABITANT_ID = "cohabitantId";
    static readonly FCM_TOKEN = "fcmToken";
}

/**
 * FirestoreドキュメントからAccountモデルに変換
 */
export class AccountConverter {
    static fromFirestore(
        snapshot: FirebaseFirestore.DocumentSnapshot
    ): Account | null {
        if (!snapshot.exists) {
            return null;
        }

        const data = snapshot.data();
        if (!data) {
            return null;
        }

        return this.fromFirestoreData(data);
    }

    static fromFirestoreData(data: FirebaseFirestore.DocumentData): Account {
        return {
            id: data[AccountFields.ID] as string,
            cohabitantId: data[AccountFields.COHABITANT_ID] as string | undefined,
            fcmToken: data[AccountFields.FCM_TOKEN] as string | undefined,
        };
    }
}
