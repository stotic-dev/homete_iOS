/**
 * Firestoreのコレクション名を一元管理するクラス
 */
export class FirestoreCollections {
    // ルートコレクション
    static readonly ACCOUNT = "Account";
    static readonly COHABITANT = "Cohabitant";

    // Cohabitantのサブコレクション
    static readonly HOUSEWORK = "Housework";
    static readonly HOUSEWORK_HISTORY = "HouseworkHistory";

    /**
     * Cohabitantのサブコレクションパスを取得
     */
    static getCohabitantSubcollection(
        cohabitantId: string,
        subcollection: string
    ): string {
        return `${this.COHABITANT}/${cohabitantId}/${subcollection}`;
    }

    /**
     * Houseworkコレクションのパスを取得
     */
    static getHouseworkPath(cohabitantId: string): string {
        return this.getCohabitantSubcollection(cohabitantId, this.HOUSEWORK);
    }

    /**
     * HouseworkHistoryコレクションのパスを取得
     */
    static getHouseworkHistoryPath(cohabitantId: string): string {
        return this.getCohabitantSubcollection(cohabitantId, this.HOUSEWORK_HISTORY);
    }
}
