/**
 * 承認待ち（pendingApproval）の家事を完了（completed）へ移行する一度きりのスクリプト
 *
 * Issue #292 で家事の承認ステータスを廃止したことに伴い、Firestoreに残っている
 * 承認待ちの家事を完了に書き換える。承認待ちは実施者が完了報告を済ませた状態なので、
 * そのまま完了として扱う。併せて、廃止した承認者の情報も削除する。
 *
 * アプリのリリース前に実行すること。旧バージョンのアプリは完了の家事をそのまま
 * 読めるため、先に実行しても表示は壊れない。
 *
 * 使い方:
 *   cd firebase/functions
 *   npm run build
 *   # 対象件数だけ確認する
 *   node lib/scripts/migratePendingApproval.js --project homete-ios-dev-e3ef7 \
 *     --dry-run
 *   # 実際に書き換える
 *   node lib/scripts/migratePendingApproval.js --project homete-ios-dev-e3ef7
 *
 * 認証は Application Default Credentials を使う。事前に
 * `gcloud auth application-default login` を実行しておくこと。
 *
 * プロジェクトIDは `homete-ios-dev` が本番、`homete-ios-dev-e3ef7` がSTG。
 * 紛らわしいため、実行時に対象プロジェクトをログへ出している。
 */
import {initializeApp} from "firebase-admin/app";
import {
  DocumentData,
  FieldValue,
  getFirestore,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import {FirestoreCollections} from "../models/FirestoreCollections";

/** 1バッチで書き込む最大件数（Firestoreのバッチ上限は500） */
const BATCH_SIZE = 500;

/** 廃止したステータスのキー */
const PENDING_APPROVAL_KEY = "pendingApproval";

/** 移行後のステータス。payloadを持たないenumのCodable表現に合わせる */
const COMPLETED_STATE = {completed: {}};

/** 廃止した承認情報のフィールド */
const REMOVED_FIELDS = ["reviewerId", "approvedAt", "reviewerComment"];

interface MigrationOptions {
  projectId: string;
  dryRun: boolean;
}

/**
 * コマンドライン引数を解釈する
 * @param {string[]} argv process.argv
 * @return {MigrationOptions} 実行オプション
 */
function parseOptions(argv: string[]): MigrationOptions {
  const args = argv.slice(2);
  const projectIndex = args.indexOf("--project");
  const projectId =
    projectIndex >= 0 ? args[projectIndex + 1] : undefined;

  if (!projectId) {
    throw new Error(
      "--project <projectId> is required " +
        "(homete-ios-dev-e3ef7: stg, homete-ios-dev: prod)"
    );
  }

  return {projectId, dryRun: args.includes("--dry-run")};
}

/**
 * 承認待ちの家事かどうかを判定する
 * @param {QueryDocumentSnapshot<DocumentData>} doc 家事ドキュメント
 * @return {boolean} 承認待ちならtrue
 */
function isPendingApproval(
  doc: QueryDocumentSnapshot<DocumentData>
): boolean {
  const state = doc.data()["state"];
  if (!state || typeof state !== "object") {
    return false;
  }
  return PENDING_APPROVAL_KEY in state;
}

/**
 * 1つの同居人グループの家事を移行する
 * @param {string} cohabitantId 対象の同居人グループID
 * @param {boolean} dryRun 書き込みを行わない場合true
 * @return {Promise<number>} 対象となった家事の件数
 */
async function migrateCohabitant(
  cohabitantId: string,
  dryRun: boolean
): Promise<number> {
  const db = getFirestore();
  const collectionRef = db
    .collection(FirestoreCollections.COHABITANT)
    .doc(cohabitantId)
    .collection(FirestoreCollections.HOUSEWORKS);

  let lastDocumentId: string | null = null;
  let targetCount = 0;

  for (;;) {
    let query = collectionRef.orderBy("__name__").limit(BATCH_SIZE);
    if (lastDocumentId) {
      query = query.startAfter(lastDocumentId);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      if (!isPendingApproval(doc)) {
        continue;
      }

      targetCount += 1;
      if (dryRun) {
        continue;
      }

      const removedFields = Object.fromEntries(
        REMOVED_FIELDS.map((field) => [field, FieldValue.delete()])
      );
      batch.update(doc.ref, {state: COMPLETED_STATE, ...removedFields});
      batchCount += 1;
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    if (snapshot.size < BATCH_SIZE) {
      break;
    }
    lastDocumentId = snapshot.docs[snapshot.docs.length - 1].id;
  }

  return targetCount;
}

/**
 * 全ての同居人グループの家事を移行する
 * @param {MigrationOptions} options 実行オプション
 * @return {Promise<void>}
 */
async function migrate(options: MigrationOptions): Promise<void> {
  initializeApp({projectId: options.projectId});

  const db = getFirestore();
  const cohabitants = await db
    .collection(FirestoreCollections.COHABITANT)
    .get();

  console.log(
    `[${options.projectId}] ${cohabitants.size} cohabitant group(s) found.` +
      (options.dryRun ? " (dry-run)" : "")
  );

  let total = 0;
  for (const cohabitant of cohabitants.docs) {
    const count = await migrateCohabitant(cohabitant.id, options.dryRun);
    total += count;
    if (count > 0) {
      console.log(`  ${cohabitant.id}: ${count} housework(s)`);
    }
  }

  const verb = options.dryRun ? "found" : "migrated";
  console.log(`[${options.projectId}] ${total} housework(s) ${verb}.`);
}

migrate(parseOptions(process.argv)).catch((error) => {
  console.error(error);
  process.exit(1);
});
