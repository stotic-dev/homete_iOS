/**
 * Cohabitantドキュメントの構造（Functionsで使用するプロパティのみ）
 */
export interface Cohabitant {
    members: string[];
}

/**
 * Cohabitantドキュメントのフィールド名定数
 */
export class CohabitantFields {
  static readonly MEMBERS = "members";
}

/**
 * FirestoreドキュメントからCohabitantモデルに変換
 */
export class CohabitantConverter {
  /**
     * Firestoreスナップショットから変換
     * @param {FirebaseFirestore.DocumentSnapshot} snapshot スナップショット
     * @return {Cohabitant | null} Cohabitantオブジェクトまたはnull
     */
  static fromFirestore(
    snapshot: FirebaseFirestore.DocumentSnapshot
  ): Cohabitant | null {
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
     * @return {Cohabitant} Cohabitantオブジェクト
     */
  static fromFirestoreData(data: FirebaseFirestore.DocumentData): Cohabitant {
    return {
      members: (data[CohabitantFields.MEMBERS] as string[]) || [],
    };
  }
}
