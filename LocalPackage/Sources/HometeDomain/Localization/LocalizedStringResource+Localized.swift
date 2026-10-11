//
//  LocalizedStringResource+Localized.swift
//  HometeDomain
//

import Foundation

public extension LocalizedStringResource {

    /// 呼び出し元モジュールのString Catalogを引く文言を作る
    ///
    /// `Button`や`navigationTitle`のように`bundle`を受け取れないAPIへ文言を渡すときに使う。
    /// リテラルをそのまま渡すと`Bundle.main`を引いてしまい、パッケージ内のString Catalogの訳が使われない。
    /// - Parameter bundle: 省略すると`#bundle`が**呼び出し元で**展開され、呼び出し元モジュールのbundleになる
    /// - Note: `keyAndValue`は日本語の文言そのもの。ビルド時に呼び出し元モジュールの`Localizable.xcstrings`へ抽出される。
    ///         `@_semantics`はFoundationの`LocalizedStringResource.init`と同じ指定で、これが無いと`comment`が抽出されない
    @_semantics("string.init_localized")
    static func localized(
        _ keyAndValue: String.LocalizationValue,
        comment: StaticString? = nil,
        bundle: Bundle = #bundle
    ) -> Self {
        .init(keyAndValue, bundle: bundle, comment: comment)
    }

    /// 文字列にする
    ///
    /// 画面の外（通知の文面など）で文字列が必要なときに使う。
    /// - Parameter locale: 訳の言語。`nil`ならアプリが表示している言語になる
    /// - Note: 訳の言語はOSの言語設定ではなく、実行中のアプリ（メインbundle）が対応している言語で決まる。
    ///         ローカライズを持たない`swift test`のランナーでは常に英語になるため、テストでは`locale`を指定する
    func resolved(locale: Locale? = nil) -> String {
        var resource = self
        if let locale {
            resource.locale = locale
        }
        return String(localized: resource)
    }

}
