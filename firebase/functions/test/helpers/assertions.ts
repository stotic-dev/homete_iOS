import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { FirestoreCollections } from '../../src/models/FirestoreCollections';

/**
 * Accountドキュメントが削除されていることを確認（ポーリング方式）
 */
export async function expectAccountNotExists(
    userId: string,
    timeoutMs: number = 5000
): Promise<void> {
    const db = getFirestore();
    const startTime = Date.now();

    while (Date.now() - startTime < timeoutMs) {
        const snapshot = await db
            .collection(FirestoreCollections.ACCOUNT)
            .where('id', '==', userId)
            .get();

        if (snapshot.empty) {
            return; // 削除された
        }

        await new Promise((resolve) => setTimeout(resolve, 100)); // 100ms待機
    }

    // タイムアウト
    throw new Error(`Account for user ${userId} still exists after ${timeoutMs}ms`);
}

/**
 * Cohabitantドキュメントが存在しないことを確認（ポーリング方式）
 */
export async function expectCohabitantNotExists(
    cohabitantId: string,
    timeoutMs: number = 5000
): Promise<void> {
    const db = getFirestore();
    const startTime = Date.now();

    while (Date.now() - startTime < timeoutMs) {
        const doc = await db
            .collection(FirestoreCollections.COHABITANT)
            .doc(cohabitantId)
            .get();

        if (!doc.exists) {
            return; // 削除された
        }

        await new Promise((resolve) => setTimeout(resolve, 100)); // 100ms待機
    }

    // タイムアウト
    throw new Error(`Cohabitant ${cohabitantId} still exists after ${timeoutMs}ms`);
}

/**
 * Cohabitantのメンバーリストを確認（ポーリング方式）
 */
export async function expectCohabitantMembers(
    cohabitantId: string,
    expectedMembers: string[],
    timeoutMs: number = 5000
): Promise<void> {
    const db = getFirestore();
    const startTime = Date.now();

    while (Date.now() - startTime < timeoutMs) {
        const doc = await db
            .collection(FirestoreCollections.COHABITANT)
            .doc(cohabitantId)
            .get();

        if (doc.exists) {
            const data = doc.data();
            const members = data?.members || [];

            // メンバーリストが一致したら成功
            if (JSON.stringify(members.sort()) === JSON.stringify(expectedMembers.sort())) {
                return;
            }
        }

        await new Promise((resolve) => setTimeout(resolve, 100)); // 100ms待機
    }

    // タイムアウト
    throw new Error(`Cohabitant ${cohabitantId} members did not match expected after ${timeoutMs}ms`);
}

/**
 * サブコレクションが空であることを確認（ポーリング方式）
 */
export async function expectSubcollectionEmpty(
    cohabitantId: string,
    subcollection: string,
    timeoutMs: number = 5000
): Promise<void> {
    const db = getFirestore();
    const path = FirestoreCollections.getCohabitantSubcollection(
        cohabitantId,
        subcollection
    );
    const startTime = Date.now();

    while (Date.now() - startTime < timeoutMs) {
        const snapshot = await db.collection(path).get();

        if (snapshot.empty) {
            return; // 空になった
        }

        await new Promise((resolve) => setTimeout(resolve, 100)); // 100ms待機
    }

    // タイムアウト
    throw new Error(`Subcollection ${subcollection} for ${cohabitantId} is not empty after ${timeoutMs}ms`);
}

/**
 * Firebase Authユーザーが存在しないことを確認
 */
export async function expectAuthUserNotExists(userId: string): Promise<void> {
    const auth = getAuth();
    try {
        await auth.getUser(userId);
        throw new Error(`Auth user ${userId} still exists`);
    } catch (error: any) {
        if (error.code !== 'auth/user-not-found') {
            throw error;
        }
    }
}
