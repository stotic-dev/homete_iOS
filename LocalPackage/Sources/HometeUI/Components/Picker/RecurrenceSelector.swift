//
//  RecurrenceSelector.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/26.
//

import HometeDomain
import SwiftUI

/// 家事の繰り返し方（毎週 / 毎月◯日 / 毎月第N◯曜日）を選ぶコンポーネント。
///
/// 入力値を描画して変更を伝えるだけで、入力が完了しているかの判定は呼び出し側が`HouseworkRecurrenceInput.isValid`などで行う。
public struct RecurrenceSelector: View {

    @Binding var input: HouseworkRecurrenceInput
    let kinds: [HouseworkRecurrenceInput.Kind]

    /// - Parameter kinds: 選べる種類。「くり返さない」を選ばせたい場合は`.none`を含める
    public init(
        input: Binding<HouseworkRecurrenceInput>,
        kinds: [HouseworkRecurrenceInput.Kind] = [.weekly, .monthlyDay, .monthlyWeekday]
    ) {
        _input = input
        self.kinds = kinds
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            Picker("くり返し", selection: $input.kind) {
                ForEach(kinds, id: \.self) { kind in
                    Text(kind.label)
                        .tag(kind)
                }
            }
            .pickerStyle(.segmented)
            kindContent()
        }
        // 日付・週のメニューを、パッケージ内のPreviewでもアプリと同じアクセントカラーで表示する
        .tint(.accent)
    }

}

// MARK: - UI定義

private extension RecurrenceSelector {

    @ViewBuilder
    func kindContent() -> some View {
        switch input.kind {
        case .none:
            EmptyView()

        case .weekly:
            WeekdaySelector(selection: $input.weekdays)

        case .monthlyDay:
            dayOfMonthContent()

        case .monthlyWeekday:
            weekdayOfMonthContent()
        }
    }

    func dayOfMonthContent() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            HStack(spacing: .space4) {
                Text("毎月")
                    .font(with: .body)
                    .foregroundStyle(.onSurface)
                Picker("日付", selection: $input.dayOfMonth) {
                    ForEach(1 ... 31, id: \.self) { day in
                        Text("\(day)日")
                            .tag(day)
                    }
                }
                .pickerStyle(.menu)
            }
            if input.dayOfMonth >= 29 {
                Text("\(input.dayOfMonth)日がない月は、月末に表示されます")
                    .font(with: .caption)
                    .foregroundStyle(.onSubSurface)
            }
        }
    }

    func weekdayOfMonthContent() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            HStack(spacing: .space4) {
                Text("毎月")
                    .font(with: .body)
                    .foregroundStyle(.onSurface)
                Picker("週", selection: $input.ordinal) {
                    ForEach(WeekOrdinal.allCases, id: \.self) { ordinal in
                        Text(ordinal.label)
                            .tag(ordinal)
                    }
                }
                .pickerStyle(.menu)
                Text("\(input.monthlyDayOfWeek.fullLabel)")
                    .font(with: .body)
                    .foregroundStyle(.onSurface)
            }
            HStack(spacing: .space8) {
                ForEach(DayOfWeek.displayOrdered) { day in
                    Button {
                        input.monthlyDayOfWeek = day
                    } label: {
                        WeekdayLabel(weekday: day, isSelected: input.monthlyDayOfWeek == day)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

}

private extension HouseworkRecurrenceInput.Kind {

    var label: String {
        switch self {
        case .none: "しない"
        case .weekly: "毎週"
        case .monthlyDay: "毎月（日付）"
        case .monthlyWeekday: "毎月（曜日）"
        }
    }

}

#if DEBUG
#Preview("RecurrenceSelector_しない", traits: .sizeThatFitsLayout) {
    RecurrenceSelector(
        input: .constant(.init(kind: .none)),
        kinds: [.none, .weekly, .monthlyDay, .monthlyWeekday]
    )
    .padding()
}

#Preview("RecurrenceSelector_毎週", traits: .sizeThatFitsLayout) {
    RecurrenceSelector(input: .constant(.init(kind: .weekly, weekdays: [.monday, .thursday])))
        .padding()
}

#Preview("RecurrenceSelector_毎月日付", traits: .sizeThatFitsLayout) {
    RecurrenceSelector(input: .constant(.init(kind: .monthlyDay, dayOfMonth: 25)))
        .padding()
}

#Preview("RecurrenceSelector_毎月日付_月末", traits: .sizeThatFitsLayout) {
    RecurrenceSelector(input: .constant(.init(kind: .monthlyDay, dayOfMonth: 31)))
        .padding()
}

#Preview("RecurrenceSelector_毎月曜日", traits: .sizeThatFitsLayout) {
    RecurrenceSelector(input: .constant(.init(
        kind: .monthlyWeekday,
        ordinal: .second,
        monthlyDayOfWeek: .wednesday
    )))
    .padding()
}
#endif
