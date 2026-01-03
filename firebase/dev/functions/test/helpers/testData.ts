import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { FirestoreCollections } from '../../src/models/FirestoreCollections';

export interface TestUser {
    uid: string;
    email: string;
}

export interface TestCohabitant {
    id: string;
    members: string[];
}

/**
 * テストユーザーを作成
 */
export async function createTestUser(uid: string, email: string): Promise<TestUser> {
    const auth = getAuth();
    await auth.createUser({ uid, email });
    return { uid, email };
}

/**
 * テスト用Accountドキュメントを作成
 */
export async function createTestAccount(
    userId: string,
    cohabitantId?: string,
    fcmToken?: string
): Promise<void> {
    const db = getFirestore();
    const data: any = {
        id: userId,
    };

    // undefinedの場合はフィールド自体を追加しない
    if (cohabitantId !== undefined) {
        data.cohabitantId = cohabitantId;
    }
    if (fcmToken !== undefined) {
        data.fcmToken = fcmToken;
    }

    await db.collection(FirestoreCollections.ACCOUNT).add(data);
}

/**
 * テストCohabitantドキュメントを作成
 */
export async function createTestCohabitant(
    cohabitantId: string,
    members: string[]
): Promise<TestCohabitant> {
    const db = getFirestore();
    await db.collection(FirestoreCollections.COHABITANT).doc(cohabitantId).set({
        members,
    });
    return { id: cohabitantId, members };
}

/**
 * Cohabitantのサブコレクションにテストデータを追加
 */
export async function createTestHousework(
    cohabitantId: string,
    houseworkId: string,
    data: any
): Promise<void> {
    const db = getFirestore();
    const path = FirestoreCollections.getHouseworkPath(cohabitantId);
    await db.collection(path).doc(houseworkId).set(data);
}
