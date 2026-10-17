//
//  FirebaseConfigurator.swift
//

import FirebaseCore

/// Firebaseを初期化する。
///
/// アプリ本体にFirebase SDKを直接リンクさせないよう、初期化もこのモジュールに置く。
/// バージョンの指定を`LocalPackage/Package.swift`の1か所に保つため。
public enum FirebaseConfigurator {

    /// 初期化済みかどうか。プレビュー・ユニットテストでは初期化しないため、Firebaseに触る前に確認する
    public static var isConfigured: Bool {
        FirebaseApp.app() != nil
    }

    /// メインバンドルの`GoogleService-Info.plist`で初期化する
    public static func configure() {
        FirebaseApp.configure()
    }

    /// 指定した設定ファイルで初期化する。ファイルを読めなければ初期化しない
    public static func configure(optionsFilePath: String) {
        guard let options = FirebaseOptions(contentsOfFile: optionsFilePath) else { return }
        FirebaseApp.configure(options: options)
    }

}
