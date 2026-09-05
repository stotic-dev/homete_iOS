/**
 * iOSクライアントが実際に読み書きするFirestoreコレクション名。
 *
 * `LocalPackage/Sources/HometeInfrastructure/Firestore/Reference/`
 * `CollectionPath.swift` の定義をテスト側に写したもの。
 *
 * プロダクションコード（`src/models/FirestoreCollections.ts`）の定数を
 * 参照してしまうと、名前がクライアントとズレたときにテストも同じ値を見に行き
 * ズレを検知できない（Issue #192 はこれで見逃されていた）。
 * そのため意図的に独立した定義として持つ。
 */
export const ClientCollections = {
  ACCOUNT: "Account",
  COHABITANT: "Cohabitant",
  HOUSEWORKS: "Houseworks",
  HOUSEWORK_TEMPLATES: "HouseworkTemplates",
  HOUSEWORK_TEMPLATE_DAYS: "Days",
  HOUSEWORK_TEMPLATE_EDITORS: "Editors",
} as const;

/**
 * Houseworksコレクションのパスを取得
 * @param {string} cohabitantId - CohabitantドキュメントのID
 * @return {string} Houseworksコレクションへのパス
 */
export function houseworksPath(cohabitantId: string): string {
  return `${ClientCollections.COHABITANT}/${cohabitantId}/` +
    `${ClientCollections.HOUSEWORKS}`;
}

/**
 * HouseworkTemplatesコレクションのパスを取得
 * @param {string} cohabitantId - CohabitantドキュメントのID
 * @return {string} HouseworkTemplatesコレクションへのパス
 */
export function houseworkTemplatesPath(cohabitantId: string): string {
  return `${ClientCollections.COHABITANT}/${cohabitantId}/` +
    `${ClientCollections.HOUSEWORK_TEMPLATES}`;
}

/**
 * テンプレート配下のDaysコレクションのパスを取得
 * @param {string} cohabitantId - CohabitantドキュメントのID
 * @param {string} templateId - テンプレートドキュメントのID
 * @return {string} Daysコレクションへのパス
 */
export function houseworkTemplateDaysPath(
  cohabitantId: string,
  templateId: string
): string {
  return `${houseworkTemplatesPath(cohabitantId)}/${templateId}/` +
    `${ClientCollections.HOUSEWORK_TEMPLATE_DAYS}`;
}

/**
 * テンプレート配下のEditorsコレクションのパスを取得
 * @param {string} cohabitantId - CohabitantドキュメントのID
 * @param {string} templateId - テンプレートドキュメントのID
 * @return {string} Editorsコレクションへのパス
 */
export function houseworkTemplateEditorsPath(
  cohabitantId: string,
  templateId: string
): string {
  return `${houseworkTemplatesPath(cohabitantId)}/${templateId}/` +
    `${ClientCollections.HOUSEWORK_TEMPLATE_EDITORS}`;
}

/**
 * Accountドキュメントのパスを取得
 * @param {string} userId - Firebase AuthのユーザーID
 * @return {string} Accountドキュメントへのパス
 */
export function accountPath(userId: string): string {
  return `${ClientCollections.ACCOUNT}/${userId}`;
}

/**
 * Cohabitantドキュメントのパスを取得
 * @param {string} cohabitantId - CohabitantドキュメントのID
 * @return {string} Cohabitantドキュメントへのパス
 */
export function cohabitantPath(cohabitantId: string): string {
  return `${ClientCollections.COHABITANT}/${cohabitantId}`;
}
