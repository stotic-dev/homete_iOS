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
    /// - Note: `keyAndValue`は日本語の文言そのもの。ビルド時に呼び出し元モジュールの`Localizable.xcstrings`へ抽出される
    static func localized(
        _ keyAndValue: String.LocalizationValue,
        comment: StaticString? = nil,
        bundle: Bundle = #bundle
    ) -> Self {
        .init(keyAndValue, bundle: bundle, comment: comment)
    }

}
