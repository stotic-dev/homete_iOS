//
//  HouseworkPostponeConfirmationAlert.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事を別の日へまわす前の確認のアラートを出し、了承されたらまわす
///
/// クイックアクションのメニュー（`.contextMenu`の中）からはアラートを出せないため、メニューを置いた画面に付ける。
/// 家事ボード・ホームの今日の家事・未完了の家事・家事詳細のどこから確かめても同じ文言と処理にするため、
/// 1つのModifierにまとめている。
struct HouseworkPostponeConfirmationAlert: ViewModifier {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.loginContext) var loginContext
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.houseworkStoragePolicy) var storagePolicy
    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale
    @Environment(\.timeZone) var timeZone

    @Binding var confirmation: HouseworkPostponeConfirmation?
    let step: HouseworkAnalyticsStep
    let onPostponed: () -> Void
    let onError: (Error) -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                title,
                isPresented: isPresented,
                presenting: confirmation
            ) { confirmation in
                Button(confirmButtonTitle(confirmation.reason)) {
                    Task {
                        await postpone(confirmation)
                    }
                }
                Button(.localized("キャンセル"), role: .cancel) {}
            } message: { confirmation in
                Text(message(confirmation))
            }
    }

}

private extension HouseworkPostponeConfirmationAlert {

    var isPresented: Binding<Bool> {
        .init(
            get: { confirmation != nil },
            set: { isPresented in
                if !isPresented {
                    confirmation = nil
                }
            }
        )
    }

    var title: LocalizedStringResource {
        switch confirmation?.reason {
        case .merge:
            .localized("まとめてまわしますか？")

        case .sameTitle, nil:
            .localized("このまままわしますか？")
        }
    }

    func confirmButtonTitle(_ reason: HouseworkPostponeConfirmation.Reason) -> LocalizedStringResource {
        switch reason {
        case .merge:
            .localized("まとめる")

        case .sameTitle:
            .localized("まわす")
        }
    }

    func message(_ confirmation: HouseworkPostponeConfirmation) -> LocalizedStringResource {
        let dateText = destinationText(confirmation.destination)
        let title = confirmation.item.title
        switch confirmation.reason {
        case .merge:
            return .localized("\(dateText)にも「\(title)」があるので、その日の分にまとめます。")

        case .sameTitle:
            return .localized("\(dateText)には「\(title)」がすでにあります。")
        }
    }

    func destinationText(_ destination: Date) -> String {
        let format = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: timeZone)
            .month()
            .day()
        return destination.formatted(format)
    }

    func postpone(_ confirmation: HouseworkPostponeConfirmation) async {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        do {
            let result = try await houseworkListStore.postpone(
                confirmation,
                templateContext: templateContext,
                storagePolicy: storagePolicy,
                cohabitantId: cohabitantId,
                step: step
            )
            if result == .postponed {
                onPostponed()
            }
        } catch {
            onError(error)
        }
    }

}

public extension View {

    /// 家事を別の日へまわす前の確認のアラートを出し、了承されたらまわす
    /// - Parameters:
    ///   - confirmation: 確かめる内容。`nil`以外にするとアラートを出す
    ///   - onPostponed: まわし終えたときに呼ぶ（家事詳細を閉じるのに使う）
    func houseworkPostponeConfirmation(
        _ confirmation: Binding<HouseworkPostponeConfirmation?>,
        step: HouseworkAnalyticsStep,
        onPostponed: @escaping () -> Void = {},
        onError: @escaping (Error) -> Void
    ) -> some View {
        modifier(
            HouseworkPostponeConfirmationAlert(
                confirmation: confirmation,
                step: step,
                onPostponed: onPostponed,
                onError: onError
            )
        )
    }

}
