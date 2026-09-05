import {readFileSync} from "fs";
import {resolve} from "path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  where,
} from "firebase/firestore";
import {
  ClientCollections,
  accountPath,
  cohabitantPath,
  houseworksPath,
  houseworkTemplateDaysPath,
  houseworkTemplateEditorsPath,
  houseworkTemplatesPath,
} from "../helpers/clientCollections";

/**
 * firestore.rules のユニットテスト。
 *
 * E2Eテスト（test/e2e）はAdmin SDKを使うためルールを迂回してしまい、
 * クライアントから見た権限は検証できない。ここではクライアントSDKを
 * エミュレーターに接続し、iOSアプリが実際に投げるのと同じ形の
 * 読み書き・クエリでルールを検証する。
 */

/** グループのメンバー */
const ALICE = "alice-uid";
/** グループのもう一人のメンバー */
const BOB = "bob-uid";
/** グループ外の認証済みユーザー */
const MALLORY = "mallory-uid";

/** ALICEとBOBが所属するグループ */
const GROUP_ID = "group-1";
/** 誰も所属していない別グループ。無制約listが弾かれることの確認に使う */
const OTHER_GROUP_ID = "group-2";

const TEMPLATE_ID = "template-1";

/**
 * Invitationはクライアントに開かないコレクションなので
 * `clientCollections.ts` には置かず、ここで直接名前を指定する
 */
const INVITATION_COLLECTION = "Invitation";
const INVITATION_TOKEN = "invitation-token-1";

/** rules-unit-testing用のプロジェクト。E2Eテストとデータを混ぜないため別IDにする */
const RULES_TEST_PROJECT_ID = "homete-rules-test";

let testEnv: RulesTestEnvironment;

const aliceDb = () => testEnv.authenticatedContext(ALICE).firestore();
const malloryDb = () => testEnv.authenticatedContext(MALLORY).firestore();
const anonymousDb = () => testEnv.unauthenticatedContext().firestore();

const account = (userId: string, cohabitantId?: string) => ({
  id: userId,
  userName: `name-of-${userId}`,
  fcmToken: `token-of-${userId}`,
  isPremium: false,
  ...(cohabitantId ? {cohabitantId} : {}),
});

const housework = (id: string) => ({
  id,
  title: "皿洗い",
  point: 1,
  state: "incomplete",
  indexedDate: {value: new Date("2026-08-30")},
  expiredAt: new Date("2027-08-30"),
});

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: RULES_TEST_PROJECT_ID,
    firestore: {
      host: "localhost",
      port: 8080,
      rules: readFileSync(
        resolve(__dirname, "../../../firestore.rules"),
        "utf8"
      ),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  // ルールを無効化して初期データを投入する
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, cohabitantPath(GROUP_ID)), {
      id: GROUP_ID,
      members: [ALICE, BOB],
    });
    await setDoc(doc(db, cohabitantPath(OTHER_GROUP_ID)), {
      id: OTHER_GROUP_ID,
      members: ["someone-else"],
    });

    await setDoc(doc(db, accountPath(ALICE)), account(ALICE, GROUP_ID));
    await setDoc(doc(db, accountPath(BOB)), account(BOB, GROUP_ID));
    // MALLORYは自分のcohabitantIdにGROUP_IDを詐称しているが、
    // GROUP_IDのmembersには含まれていない
    await setDoc(doc(db, accountPath(MALLORY)), account(MALLORY, GROUP_ID));

    await setDoc(
      doc(db, `${houseworksPath(GROUP_ID)}/housework-1`),
      housework("housework-1")
    );
    await setDoc(
      doc(db, `${houseworkTemplatesPath(GROUP_ID)}/${TEMPLATE_ID}`),
      {templateId: TEMPLATE_ID, name: "平日", version: 0}
    );
    await setDoc(
      doc(db, `${houseworkTemplateDaysPath(GROUP_ID, TEMPLATE_ID)}/1`),
      {dayOfWeek: 1, items: []}
    );
    await setDoc(
      doc(db, `${houseworkTemplateEditorsPath(GROUP_ID, TEMPLATE_ID)}/${BOB}`),
      {userId: BOB, updatedAt: new Date(), expiredAt: new Date()}
    );

    await setDoc(doc(db, `${INVITATION_COLLECTION}/${INVITATION_TOKEN}`), {
      cohabitantId: GROUP_ID,
      expiresAt: new Date("2027-08-30"),
    });
  });
});

describe("Cohabitant", () => {
  it("メンバーはグループを取得できる", async () => {
    await assertSucceeds(
      getDoc(doc(aliceDb(), cohabitantPath(GROUP_ID)))
    );
  });

  it("非メンバーはグループを取得できない", async () => {
    await assertFails(
      getDoc(doc(malloryDb(), cohabitantPath(GROUP_ID)))
    );
  });

  it("メンバーでもidを指定したクエリでは取得できない", async () => {
    // `list`はクエリ内容だけで判定されるためmembersを見られない。
    // ImplCohabitantClientをドキュメント購読に変えた前提を固定する
    const snapshot = query(
      collection(aliceDb(), ClientCollections.COHABITANT),
      where("id", "==", GROUP_ID)
    );
    await assertFails(getDocs(snapshot));
  });

  it("メンバーでもグループ全件の一覧は取得できない", async () => {
    await assertFails(
      getDocs(collection(aliceDb(), ClientCollections.COHABITANT))
    );
  });

  it("未認証ユーザーはグループを取得できない", async () => {
    await assertFails(
      getDoc(doc(anonymousDb(), cohabitantPath(GROUP_ID)))
    );
  });

  it("自分をmembersに含む新規グループを作成できる", async () => {
    await assertSucceeds(
      setDoc(doc(malloryDb(), cohabitantPath("new-group")), {
        id: "new-group",
        members: [MALLORY, ALICE],
      })
    );
  });

  it("自分をmembersに含まないグループは作成できない", async () => {
    await assertFails(
      setDoc(doc(malloryDb(), cohabitantPath("new-group")), {
        id: "new-group",
        members: [ALICE, BOB],
      })
    );
  });

  it("ドキュメントIDとidフィールドが一致しないと作成できない", async () => {
    await assertFails(
      setDoc(doc(malloryDb(), cohabitantPath("new-group")), {
        id: "another-id",
        members: [MALLORY],
      })
    );
  });

  it("非メンバーはmembersを書き換えられない", async () => {
    await assertFails(
      setDoc(doc(malloryDb(), cohabitantPath(GROUP_ID)), {
        id: GROUP_ID,
        members: [ALICE, BOB, MALLORY],
      })
    );
  });

  it("メンバーはmembersを更新できる", async () => {
    await assertSucceeds(
      setDoc(doc(aliceDb(), cohabitantPath(GROUP_ID)), {
        id: GROUP_ID,
        members: [ALICE, BOB, MALLORY],
      })
    );
  });

  it("メンバーでもグループを削除できない", async () => {
    await assertFails(
      deleteDoc(doc(aliceDb(), cohabitantPath(GROUP_ID)))
    );
  });
});

describe("Account", () => {
  it("本人は自分のAccountを取得できる", async () => {
    await assertSucceeds(getDoc(doc(aliceDb(), accountPath(ALICE))));
  });

  it("本人は自分のAccountを更新できる", async () => {
    await assertSucceeds(
      setDoc(doc(aliceDb(), accountPath(ALICE)), account(ALICE, GROUP_ID))
    );
  });

  it("同じグループのメンバーのAccountを取得できる", async () => {
    // CohabitantStoreがメンバー一覧のuserNameを引くのに必要
    await assertSucceeds(getDoc(doc(aliceDb(), accountPath(BOB))));
  });

  it("cohabitantIdを詐称してもmembers外なら他人のAccountは取得できない",
    async () => {
      await assertFails(getDoc(doc(malloryDb(), accountPath(ALICE))));
    });

  it("他人のAccountは書き換えられない", async () => {
    await assertFails(
      setDoc(doc(malloryDb(), accountPath(ALICE)), account(ALICE, GROUP_ID))
    );
  });

  it("idフィールドがuidと一致しないAccountは書き込めない", async () => {
    await assertFails(
      setDoc(doc(malloryDb(), accountPath(MALLORY)), {
        ...account(MALLORY),
        id: ALICE,
      })
    );
  });

  it("Accountの一覧は取得できない", async () => {
    await assertFails(
      getDocs(collection(aliceDb(), ClientCollections.ACCOUNT))
    );
  });

  it("本人でもAccountを削除できない", async () => {
    await assertFails(deleteDoc(doc(aliceDb(), accountPath(ALICE))));
  });
});

describe("Houseworks", () => {
  const houseworkDoc = (id: string) => `${houseworksPath(GROUP_ID)}/${id}`;

  it("メンバーは家事を取得できる", async () => {
    await assertSucceeds(
      getDoc(doc(aliceDb(), houseworkDoc("housework-1")))
    );
  });

  it("メンバーは家事を作成できる", async () => {
    await assertSucceeds(
      setDoc(
        doc(aliceDb(), houseworkDoc("housework-2")),
        housework("housework-2")
      )
    );
  });

  it("メンバーは家事を削除できる", async () => {
    await assertSucceeds(
      deleteDoc(doc(aliceDb(), houseworkDoc("housework-1")))
    );
  });

  it("ドキュメントIDとidフィールドが一致しない家事は作成できない",
    async () => {
      await assertFails(
        setDoc(
          doc(aliceDb(), houseworkDoc("housework-2")),
          housework("another-id")
        )
      );
    });

  it("非メンバーは家事を取得できない", async () => {
    await assertFails(
      getDoc(doc(malloryDb(), houseworkDoc("housework-1")))
    );
  });

  it("非メンバーは家事を作成できない", async () => {
    await assertFails(
      setDoc(
        doc(malloryDb(), houseworkDoc("housework-2")),
        housework("housework-2")
      )
    );
  });

  it("非メンバーは家事を削除できない", async () => {
    await assertFails(
      deleteDoc(doc(malloryDb(), houseworkDoc("housework-1")))
    );
  });
});

describe("HouseworkTemplates", () => {
  const templateDoc = `${houseworkTemplatesPath(GROUP_ID)}/${TEMPLATE_ID}`;
  const dayDoc = `${houseworkTemplateDaysPath(GROUP_ID, TEMPLATE_ID)}/1`;
  const editorDoc = (userId: string) =>
    `${houseworkTemplateEditorsPath(GROUP_ID, TEMPLATE_ID)}/${userId}`;

  it("メンバーはテンプレートを取得できる", async () => {
    await assertSucceeds(getDoc(doc(aliceDb(), templateDoc)));
  });

  it("メンバーはテンプレート一覧を取得できる", async () => {
    await assertSucceeds(
      getDocs(collection(aliceDb(), houseworkTemplatesPath(GROUP_ID)))
    );
  });

  it("メンバーはDaysを更新できる", async () => {
    await assertSucceeds(
      setDoc(doc(aliceDb(), dayDoc), {dayOfWeek: 1, items: []})
    );
  });

  it("非メンバーはテンプレートを取得できない", async () => {
    await assertFails(getDoc(doc(malloryDb(), templateDoc)));
  });

  it("非メンバーはDaysを更新できない", async () => {
    await assertFails(
      setDoc(doc(malloryDb(), dayDoc), {dayOfWeek: 1, items: []})
    );
  });

  it("メンバーは他メンバーの編集ロックを取得できる", async () => {
    await assertSucceeds(getDoc(doc(aliceDb(), editorDoc(BOB))));
  });

  it("メンバーは自分の編集ロックを作成・削除できる", async () => {
    await assertSucceeds(
      setDoc(doc(aliceDb(), editorDoc(ALICE)), {
        userId: ALICE,
        updatedAt: new Date(),
        expiredAt: new Date(),
      })
    );
    await assertSucceeds(deleteDoc(doc(aliceDb(), editorDoc(ALICE))));
  });

  it("メンバーでも他人の編集ロックは作成・削除できない", async () => {
    await assertFails(
      setDoc(doc(aliceDb(), editorDoc(BOB)), {
        userId: BOB,
        updatedAt: new Date(),
        expiredAt: new Date(),
      })
    );
    await assertFails(deleteDoc(doc(aliceDb(), editorDoc(BOB))));
  });
});

describe("Invitation", () => {
  const invitationDoc = `${INVITATION_COLLECTION}/${INVITATION_TOKEN}`;

  it("メンバーでも招待トークンは取得できない", async () => {
    await assertFails(getDoc(doc(aliceDb(), invitationDoc)));
  });

  it("招待トークンの一覧は取得できない", async () => {
    // ドキュメントIDがトークンそのものなので、列挙できると招待を悪用できる
    await assertFails(
      getDocs(collection(aliceDb(), INVITATION_COLLECTION))
    );
  });

  it("招待は作成・更新できない", async () => {
    // cohabitantId / expiresAt を差し替えてcallableの検証を迂回されないようにする
    await assertFails(
      setDoc(doc(aliceDb(), invitationDoc), {
        cohabitantId: OTHER_GROUP_ID,
        expiresAt: new Date("2027-08-30"),
      })
    );
  });

  it("招待は削除できない", async () => {
    await assertFails(deleteDoc(doc(aliceDb(), invitationDoc)));
  });
});

describe("未定義のコレクション", () => {
  it("ルールで許可していないコレクションは読み書きできない", async () => {
    await assertFails(
      getDoc(doc(aliceDb(), "DailyHouseworks/any-id"))
    );
    await assertFails(
      setDoc(doc(aliceDb(), "DailyHouseworks/any-id"), {value: 1})
    );
  });
});
