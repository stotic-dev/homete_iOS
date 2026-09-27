public enum HouseworkTemplateError: Error, Sendable {

    /// 楽観的ロックで version が変わっていた場合
    case versionConflict
    /// テンプレートの読み込みが終わっていない（読み込み中・失敗）ため、テンプレートの有無を判断できない場合
    case notLoaded

}
