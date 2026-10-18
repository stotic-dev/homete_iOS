//
//  ScreenTutorialStateClient.swift
//  LocalPackage
//

/// 画面を初めて開いたときに出すチュートリアルを、見たかどうかを画面ごとに永続化するClient
/// - Note: 記録は端末単位とし、再インストール・機種変更では引き継がない
public struct ScreenTutorialStateClient: Sendable {

    /// チュートリアルを見たかどうかを読み出す。記録が無ければ`false`
    public let loadHasSeen: @Sendable (ScreenTutorial) async -> Bool
    /// チュートリアルを見たかどうかを記録する
    public let saveHasSeen: @Sendable (ScreenTutorial, Bool) async -> Void

    public init(
        loadHasSeen: @Sendable @escaping (ScreenTutorial) async -> Bool = { _ in true },
        saveHasSeen: @Sendable @escaping (ScreenTutorial, Bool) async -> Void = { _, _ in }
    ) {
        self.loadHasSeen = loadHasSeen
        self.saveHasSeen = saveHasSeen
    }

}

public extension ScreenTutorialStateClient {

    /// Previewではチュートリアルを出さない
    static let previewValue: ScreenTutorialStateClient = .init()

}
