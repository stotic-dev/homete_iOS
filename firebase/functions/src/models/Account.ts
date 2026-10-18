/**
 * Accountドキュメントの構造（Functionsで使用するプロパティのみ）
 */
export interface Account {
    id: string;
    userName?: string;
    cohabitantId?: string;
    /**
     * 旧バージョンのアプリが書き込むFCMトークン
     *
     * 新しいアプリは`Account/{uid}/Private/fcm`へ書き込み、このフィールドを消す（#241）。
     * 旧アプリの利用者に通知を届けるためだけに読む。
     */
    fcmToken?: string;
    isPremium: boolean;
}

/**
 * Accountドキュメントのフィールド名定数
 */
export class AccountFields {
  static readonly ID = "id";
  static readonly USER_NAME = "userName";
  static readonly COHABITANT_ID = "cohabitantId";
  static readonly FCM_TOKEN = "fcmToken";
  static readonly IS_PREMIUM = "isPremium";
}

/**
 * `Account/{uid}/Private/fcm`ドキュメントのフィールド名定数
 */
export class AccountFcmTokenFields {
  static readonly TOKEN = "token";
}

/**
 * FirestoreドキュメントからAccountモデルに変換
 */
export class AccountConverter {
  /**
     * Firestoreスナップショットから変換
     * @param {FirebaseFirestore.DocumentSnapshot} snapshot スナップショット
     * @return {Account | null} Accountオブジェクトまたはnull
     */
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

  /**
     * Firestoreデータから変換
     * @param {FirebaseFirestore.DocumentData} data Firestoreデータ
     * @return {Account} Accountオブジェクト
     */
  static fromFirestoreData(data: FirebaseFirestore.DocumentData): Account {
    return {
      id: data[AccountFields.ID] as string,
      userName: data[AccountFields.USER_NAME] as string | undefined,
      cohabitantId: data[AccountFields.COHABITANT_ID] as string | undefined,
      fcmToken: data[AccountFields.FCM_TOKEN] as string | undefined,
      // isPremium 導入前のドキュメントにはフィールドが無いため無料プラン扱いにする
      isPremium:
        (data[AccountFields.IS_PREMIUM] as boolean | undefined) ?? false,
    };
  }
}
