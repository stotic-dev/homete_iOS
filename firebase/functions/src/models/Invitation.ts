import {Timestamp} from "firebase-admin/firestore";

/**
 * Invitationドキュメントの構造
 *
 * ドキュメントIDが招待トークンそのものになる。
 */
export interface Invitation {
    cohabitantId: string;
    createdBy: string;
    createdAt: Date;
    expiresAt: Date;
}

/**
 * Invitationドキュメントのフィールド名定数
 */
export class InvitationFields {
  static readonly COHABITANT_ID = "cohabitantId";
  static readonly CREATED_BY = "createdBy";
  static readonly CREATED_AT = "createdAt";
  static readonly EXPIRES_AT = "expiresAt";
}

/**
 * FirestoreドキュメントからInvitationモデルに変換
 */
export class InvitationConverter {
  /**
   * Firestoreスナップショットから変換
   * @param {FirebaseFirestore.DocumentSnapshot} snapshot スナップショット
   * @return {Invitation | null} Invitationオブジェクトまたはnull
   */
  static fromFirestore(
    snapshot: FirebaseFirestore.DocumentSnapshot
  ): Invitation | null {
    if (!snapshot.exists) {
      return null;
    }

    const data = snapshot.data();
    if (!data) {
      return null;
    }

    return {
      cohabitantId: data[InvitationFields.COHABITANT_ID] as string,
      createdBy: data[InvitationFields.CREATED_BY] as string,
      createdAt: (data[InvitationFields.CREATED_AT] as Timestamp).toDate(),
      expiresAt: (data[InvitationFields.EXPIRES_AT] as Timestamp).toDate(),
    };
  }
}
