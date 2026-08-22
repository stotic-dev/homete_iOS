/**
 * Firestoreのコレクション名を一元管理するクラス
 */
export class FirestoreCollections {
  // ルートコレクション
  static readonly ACCOUNT = "Account";
  static readonly COHABITANT = "Cohabitant";

  // Cohabitant配下のサブコレクション
  static readonly HOUSEWORKS = "Houseworks";
}
