//
//  CLIResponse.swift
//  AgentToolsPackage
//

/// CLI・行動テストから受け取る操作
public struct ActionRequest: Codable, Equatable, Sendable {

    public var action: String
    public var arguments: [String: String]

    public init(action: String, arguments: [String: String] = [:]) {
        self.action = action
        self.arguments = arguments
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        action = try container.decode(String.self, forKey: .action)
        arguments = try container.decodeIfPresent([String: String].self, forKey: .arguments) ?? [:]
    }

}

/// 受け付けられなかった操作
public struct IntrospectionError: Error, Codable, Equatable, Sendable {

    public enum Code: String, Codable, Sendable {

        /// JSONとして読めない、または形が違う
        case invalidRequest
        /// そういう名前の操作は無い
        case unknownAction
        /// 今の画面・状態では実行できない（シートが出ている間の背景の操作など）
        case actionNotAvailable
        /// 引数が足りない・余っている・値が読めない
        case invalidArguments

    }

    public var code: Code
    public var message: String

    public init(code: Code, message: String) {
        self.code = code
        self.message = message
    }

}

/// CLIが標準出力へ1行ずつ返すJSON
public struct CLIResponse: Codable, Equatable, Sendable {

    public struct ScenarioSummary: Codable, Equatable, Sendable {

        public var name: String
        public var summary: String

        public init(name: String, summary: String) {
            self.name = name
            self.summary = summary
        }

    }

    public var ok: Bool
    public var snapshot: AppSnapshot?
    // 返さないコマンドではJSONにキーごと出さないため、空の配列ではなくnilにする
    // swiftlint:disable:next discouraged_optional_collection
    public var scenarios: [ScenarioSummary]?
    public var error: IntrospectionError?

    public init(snapshot: AppSnapshot) {
        ok = true
        self.snapshot = snapshot
    }

    public init(scenarios: [ScenarioSummary]) {
        ok = true
        self.scenarios = scenarios
    }

    public init(error: IntrospectionError) {
        ok = false
        self.error = error
    }

}
