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
     * @param {string} cohabitantId - CohabitantドキュメントのID
     * @param {string} subcollection - サブコレクション名
     * @return {string} サブコレクションへのパス
     */
  static getCohabitantSubcollection(
    cohabitantId: string,
    subcollection: string
  ): string {
    return `${this.COHABITANT}/${cohabitantId}/${subcollection}`;
  }

  /**
     * Houseworkコレクションのパスを取得
     * @param {string} cohabitantId - CohabitantドキュメントのID
     * @return {string} Houseworkコレクションへのパス
     */
  static getHouseworkPath(cohabitantId: string): string {
    return this.getCohabitantSubcollection(cohabitantId, this.HOUSEWORK);
  }

  /**
     * HouseworkHistoryコレクションのパスを取得
     * @param {string} cohabitantId - CohabitantドキュメントのID
     * @return {string} HouseworkHistoryコレクションへのパス
     */
  static getHouseworkHistoryPath(cohabitantId: string): string {
    return this.getCohabitantSubcollection(
      cohabitantId,
      this.HOUSEWORK_HISTORY
    );
  }
}
