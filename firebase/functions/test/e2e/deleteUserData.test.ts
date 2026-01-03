import { getAuth } from 'firebase-admin/auth';
import {
    createTestUser,
    createTestAccount,
    createTestCohabitant,
    createTestHousework,
} from '../helpers/testData';
import {
    expectAccountNotExists,
    expectCohabitantNotExists,
    expectCohabitantMembers,
    expectSubcollectionEmpty,
} from '../helpers/assertions';
import { FirestoreCollections } from '../../src/models/FirestoreCollections';

describe('deleteUserData E2E Tests', () => {
    // 各テストで一意のIDを使用するためのカウンター
    let testCounter = 0;

    beforeEach(() => {
        testCounter++;
    });

    describe('2人グループのテスト', () => {
        it('2人グループで1人削除した場合、Cohabitantグループが完全削除される', async () => {
            // Arrange: テストデータ準備
            const uid1 = `test1-user-1-${testCounter}`;
            const uid2 = `test1-user-2-${testCounter}`;
            const user1 = await createTestUser(uid1, `${uid1}@example.com`);
            const user2 = await createTestUser(uid2, `${uid2}@example.com`);

            const cohabitantId = `test1-cohabitant-${testCounter}`;
            await createTestCohabitant(cohabitantId, [user1.uid, user2.uid]);

            await createTestAccount(user1.uid, cohabitantId, 'token-1');
            await createTestAccount(user2.uid, cohabitantId, 'token-2');

            // サブコレクションにテストデータを追加
            await createTestHousework(cohabitantId, 'housework-1', {
                title: 'Test Housework',
            });

            // Act: ユーザー削除（トリガー発火）
            const auth = getAuth();
            await auth.deleteUser(user1.uid);

            // Assert: 検証（ポーリングで確認）
            await expectAccountNotExists(user1.uid);
            await expectCohabitantNotExists(cohabitantId);
            await expectSubcollectionEmpty(cohabitantId, FirestoreCollections.HOUSEWORK);
        });
    });

    describe('3人以上のグループのテスト', () => {
        it('3人グループで1人削除した場合、メンバーリストから削除されるのみ', async () => {
            // Arrange
            const uid1 = `test2-user-1-${testCounter}`;
            const uid2 = `test2-user-2-${testCounter}`;
            const uid3 = `test2-user-3-${testCounter}`;
            const user1 = await createTestUser(uid1, `${uid1}@example.com`);
            const user2 = await createTestUser(uid2, `${uid2}@example.com`);
            const user3 = await createTestUser(uid3, `${uid3}@example.com`);

            const cohabitantId = `test2-cohabitant-${testCounter}`;
            await createTestCohabitant(cohabitantId, [
                user1.uid,
                user2.uid,
                user3.uid,
            ]);

            await createTestAccount(user1.uid, cohabitantId, 'token-1');
            await createTestAccount(user2.uid, cohabitantId, 'token-2');
            await createTestAccount(user3.uid, cohabitantId, 'token-3');

            // Act
            const auth = getAuth();
            await auth.deleteUser(user1.uid);

            // Assert（ポーリングで確認）
            await expectAccountNotExists(user1.uid);
            await expectCohabitantMembers(cohabitantId, [user2.uid, user3.uid]);
        });
    });

    describe('Cohabitantに所属していないユーザーのテスト', () => {
        it('Cohabitantに所属していないユーザーを削除してもエラーにならない', async () => {
            // Arrange
            const uid1 = `test3-user-1-${testCounter}`;
            const user1 = await createTestUser(uid1, `${uid1}@example.com`);
            await createTestAccount(user1.uid); // cohabitantIdなし

            // Act
            const auth = getAuth();
            await auth.deleteUser(user1.uid);

            // Assert（ポーリングで確認）
            await expectAccountNotExists(user1.uid);
        });
    });

    describe('Accountが存在しないユーザーのテスト', () => {
        it('Accountドキュメントが存在しないユーザーを削除してもエラーにならない', async () => {
            // Arrange
            const uid1 = `test4-user-1-${testCounter}`;
            const user1 = await createTestUser(uid1, `${uid1}@example.com`);
            // Accountドキュメントは作成しない

            // Act & Assert: エラーなく完了することを確認
            const auth = getAuth();
            await auth.deleteUser(user1.uid);
            // この場合はAccountが存在しないので、関数は即座に終了する
        });
    });

    describe('大量のサブコレクションデータのテスト', () => {
        it('500件以上のサブコレクションドキュメントも削除される', async () => {
            // Arrange
            const uid1 = `test5-user-1-${testCounter}`;
            const uid2 = `test5-user-2-${testCounter}`;
            const user1 = await createTestUser(uid1, `${uid1}@example.com`);
            const user2 = await createTestUser(uid2, `${uid2}@example.com`);

            const cohabitantId = `test5-cohabitant-${testCounter}`;
            await createTestCohabitant(cohabitantId, [user1.uid, user2.uid]);

            await createTestAccount(user1.uid, cohabitantId);
            await createTestAccount(user2.uid, cohabitantId);

            // 600件のHouseworkを作成（バッチ削除のテスト）
            const promises = [];
            for (let i = 0; i < 600; i++) {
                promises.push(
                    createTestHousework(cohabitantId, `housework-${i}`, {
                        title: `Housework ${i}`,
                    })
                );
            }
            await Promise.all(promises);

            // Act
            const auth = getAuth();
            await auth.deleteUser(user1.uid);

            // Assert（ポーリングで確認、大量データなのでタイムアウトを長めに）
            await expectCohabitantNotExists(cohabitantId, 10000);
            await expectSubcollectionEmpty(cohabitantId, FirestoreCollections.HOUSEWORK, 10000);
        }, 20000); // タイムアウトを20秒に設定
    });
});
