//
//  AppCheckConfigurator.swift
//

import FirebaseAppCheck
import FirebaseCore
import Foundation

/// Firebase App Checkのプロバイダを登録する。
///
/// `FirebaseApp.configure()` より前に呼ぶこと。configure時点で登録済みのファクトリが使われるため、
/// 後から登録してもApp Checkトークンは付与されない。
public enum AppCheckConfigurator {

    /// - Parameter usesDebugProvider: Xcodeから実行するローカルビルドかどうか。
    ///   App AttestはシミュレータでもXcodeの開発用署名でも動かないため、ローカルビルドでは
    ///   Debug Providerを使う（デバッグトークンの登録手順はCLAUDE.mdを参照）。
    ///   TestFlight・App Store配布のビルドでは必ずfalseを渡すこと。
    /// - Parameter debugToken: Firebaseコンソールに登録済みのデバッグトークン。Debug Providerを使うときだけ参照する。
    ///   空なら、SDKがインストールごとに生成するトークンにフォールバックする。
    public static func configure(usesDebugProvider: Bool, debugToken: String = "") {
        if usesDebugProvider, !debugToken.isEmpty {
            // SDKはこの環境変数をローカル生成のトークンより優先して読む。Xcodeのスキームで渡すと
            // ホーム画面から起動したときに渡らないため、ビルドに埋め込んだ値をここで設定する
            setenv(debugTokenEnvironmentKey, debugToken, 1)
        }
        let factory: any AppCheckProviderFactory = usesDebugProvider
            ? AppCheckDebugProviderFactory()
            : AppAttestProviderFactory()
        AppCheck.setAppCheckProviderFactory(factory)
    }

}

private extension AppCheckConfigurator {

    /// Debug Providerがデバッグトークンを読む環境変数名
    static let debugTokenEnvironmentKey = "AppCheckDebugToken"

}

// MARK: - AppAttestProviderFactory

/// App Attestを使うプロバイダファクトリ。
///
/// FirebaseSDKはDeviceCheck向けのファクトリしか用意していないため、App Attest用は自前で定義する。
private final class AppAttestProviderFactory: NSObject, AppCheckProviderFactory {

    func createProvider(with app: FirebaseApp) -> (any AppCheckProvider)? {
        AppAttestProvider(app: app)
    }

}
