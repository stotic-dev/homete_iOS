//
//  AppCheckConfigurator.swift
//

import FirebaseAppCheck
import FirebaseCore

/// Firebase App Checkのプロバイダを登録する。
///
/// `FirebaseApp.configure()` より前に呼ぶこと。configure時点で登録済みのファクトリが使われるため、
/// 後から登録してもApp Checkトークンは付与されない。
public enum AppCheckConfigurator {

    /// - Parameter usesDebugProvider: Xcodeから実行するローカルビルドかどうか。
    ///   App AttestはシミュレータでもXcodeの開発用署名でも動かないため、ローカルビルドでは
    ///   Debug Providerを使う（デバッグトークンの登録手順はCLAUDE.mdを参照）。
    ///   TestFlight・App Store配布のビルドでは必ずfalseを渡すこと。
    public static func configure(usesDebugProvider: Bool) {
        let factory: any AppCheckProviderFactory = usesDebugProvider
            ? AppCheckDebugProviderFactory()
            : AppAttestProviderFactory()
        AppCheck.setAppCheckProviderFactory(factory)
    }

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
