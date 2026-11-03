//
//  HouseworkImageErrorAlert.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

extension View {

    /// 画像の追加・削除で起きたエラーを、原因ごとの文言で知らせる
    ///
    /// 共通のエラーのアラートでは「不明のエラー」になり、読めない画像を選んだときなど、ふつうに起こることの理由が伝わらないため。
    func houseworkImageErrorAlert(_ error: Binding<HouseworkImageError?>) -> some View {
        alert(
            error.wrappedValue.map { Self.houseworkImageErrorTitle($0) } ?? .localized("画像を追加できませんでした"),
            isPresented: .init(get: { error.wrappedValue != nil }, set: { if !$0 { error.wrappedValue = nil } }),
            presenting: error.wrappedValue
        ) { _ in
            Button(.localized("閉じる"), role: .cancel) {}
        } message: { error in
            Text(Self.houseworkImageErrorMessage(error))
        }
    }

}

private extension View {

    static func houseworkImageErrorTitle(_ error: HouseworkImageError) -> LocalizedStringResource {
        switch error {
        case .notEditable, .premiumRequired, .limitExceeded:
            .localized("画像を追加できませんでした")

        case .notDeletable:
            .localized("画像を消せませんでした")

        case .unreadable:
            .localized("画像を添えられませんでした")
        }
    }

    static func houseworkImageErrorMessage(_ error: HouseworkImageError) -> LocalizedStringResource {
        switch error {
        case .notEditable:
            .localized("この家事は完了または「やらない」になったため、画像を追加できません。")

        case .premiumRequired:
            .localized("画像を添えられるのは、プレミアムプランの方だけです。")

        case .limitExceeded:
            .localized("画像は\(HouseworkImagePolicy.maxImageCount)枚まで添えられます")

        case .notDeletable:
            .localized("同居人が追加した画像は、プレミアムプランの方だけが消せます。")

        case .unreadable:
            .localized("画像を読み込めませんでした。別の写真を選んでください。")
        }
    }

}
