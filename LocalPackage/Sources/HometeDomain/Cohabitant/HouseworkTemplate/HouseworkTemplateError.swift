public enum HouseworkTemplateError: Error, Sendable {
    /// 楽観的ロックで version が変わっていた場合
    case versionConflict
}
