/**
 * Firestoreのコレクション名を一元管理するクラス
 */
export class FirestoreCollections {
  // ルートコレクション
  static readonly ACCOUNT = "Account";
  static readonly COHABITANT = "Cohabitant";
  static readonly INVITATION = "Invitation";

  // Account配下のサブコレクション（本人とAdmin SDKだけが読める値）
  static readonly ACCOUNT_PRIVATE = "Private";
  /** FCMトークンを置くACCOUNT_PRIVATE配下のドキュメントID */
  static readonly ACCOUNT_PRIVATE_FCM = "fcm";

  // Cohabitant配下のサブコレクション
  static readonly HOUSEWORKS = "Houseworks";
}
