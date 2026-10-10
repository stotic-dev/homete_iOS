//
//  RecurrenceSelector.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/26.
//

import HometeDomain
import SwiftUI

/// 家事の繰り返し方（毎日 / 毎週 / 毎月◯日）を選ぶコンポーネント。
///
/// 「くり返し」の行のメニューで種類を選び、`showsDetail`が`true`なら、その下で毎週の曜日・毎月の日付を選ばせる。
/// 入力値を描画して変更を伝えるだけで、入力が完了しているかの判定は呼び出し側が`HouseworkRecurrenceInput.isValid`などで行う。
public struct RecurrenceSelector: View {

    @Binding var input: HouseworkRecurrenceInput
    let kinds: [HouseworkRecurrenceInput.Kind]
    let titleFont: DesignSystem.Font
    let showsDetail: Bool

    /// - Parameters:
    ///   - kinds: 選べる種類。「くり返さない」を選ばせたい場合は`.none`を含める
    ///   - titleFont: 「くり返し」の見出しのフォント
    ///   - showsDetail: 毎週の曜日・毎月の日付を選ばせるか。選ばせない場合は`input`に入っている値をそのまま使う
    public init(
        input: Binding<HouseworkRecurrenceInput>,
        kinds: [HouseworkRecurrenceInput.Kind] = [.daily, .weekly, .monthly],
        titleFont: DesignSystem.Font = .headLineS,
        showsDetail: Bool = true
    ) {
        _input = input
        self.kinds = kinds
        self.titleFont = titleFont
        self.showsDetail = showsDetail
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            HStack(spacing: .space8) {
                Text("くり返し", bundle: #bundle)
                    .font(with: titleFont)
                    .foregroundStyle(.textPrimary)
                Spacer()
                Picker(.localized("くり返し"), selection: $input.kind) {
                    ForEach(kinds, id: \.self) { kind in
                        Text(kind.label)
                            .tag(kind)
                    }
                }
                .pickerStyle(.menu)
            }
            if showsDetail {
                kindContent()
            }
        }
        // メニューを、パッケージ内のPreviewでもアプリと同じアクセントカラーで表示する
        .tint(.textAccent)
    }

}

// MARK: - UI定義

private extension RecurrenceSelector {

    @ViewBuilder
    func kindContent() -> some View {
        switch input.kind {
        case .none, .daily:
            EmptyView()

        case .weekly:
            WeekdaySelector(selection: $input.weekdays)

        case .monthly:
            dayOfMonthContent()
        }
    }

    func dayOfMonthContent() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            HStack(spacing: .space4) {
                Text("毎月", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
                Picker(.localized("日付"), selection: $input.dayOfMonth) {
                    ForEach(1 ... 31, id: \.self) { day in
                        Text("\(day)日", bundle: #bundle)
                            .tag(day)
                    }
                }
                .pickerStyle(.menu)
            }
            if input.dayOfMonth >= 29 {
                Text("\(input.dayOfMonth)日がない月は、月末に表示されます", bundle: #bundle)
                    .font(with: .caption)
                    .foregroundStyle(.textPrimary)
            }
        }
    }

}

private extension HouseworkRecurrenceInput.Kind {

    var label: LocalizedStringResource {
        switch self {
        case .none: .localized("しない", comment: "家事のくり返しの種類")
        case .daily: .localized("毎日", comment: "家事のくり返しの種類")
        case .weekly: .localized("毎週", comment: "家事のくり返しの種類")
        case .monthly: .localized("毎月", comment: "家事のくり返しの種類")
        }
    }

}

#if DEBUG
#Preview("RecurrenceSelector_しない", traits: .sizeThatFitsLayout) {
    RecurrenceSelector(
        input: .constant(.init(kind: .none)),
        kinds: [.none, .daily, .weekly, .monthly]
    )
    .padding()
}

#Preview("RecurrenceSelector_毎週", traits: .sizeThatFitsLayout) {
    RecurrenceSelector(input: .constant(.init(kind: .weekly, weekdays: [.monday, .thursday])))
        .padding()
}

#Preview("RecurrenceSelector_毎月日付", traits: .sizeThatFitsLayout) {
    RecurrenceSelector(input: .constant(.init(kind: .monthly, dayOfMonth: 25)))
        .padding()
}

#Preview("RecurrenceSelector_毎月日付_月末", traits: .sizeThatFitsLayout) {
    RecurrenceSelector(input: .constant(.init(kind: .monthly, dayOfMonth: 31)))
        .padding()
}

#Preview("RecurrenceSelector_詳細なし", traits: .sizeThatFitsLayout) {
    RecurrenceSelector(
        input: .constant(.init(kind: .weekly, weekdays: [.thursday])),
        kinds: [.none, .daily, .weekly, .monthly],
        showsDetail: false
    )
    .padding()
}
#endif
