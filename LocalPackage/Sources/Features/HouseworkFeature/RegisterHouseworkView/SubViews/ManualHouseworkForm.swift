//
//  ManualHouseworkForm.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事の登録シートの「新しく入力」タブ
/// - Note: 画面の背景はシート既定のままにして「いつもの家事」タブと揃え、
///         セクションのカードとの境目は`sectionCardStyle()`の影で見せる
struct ManualHouseworkForm: View {

    @Binding var entry: RegisterHouseworkDraft.ManualEntry

    /// 「いつもの家事に保存する」で選べるカテゴリ
    let categories: [FrequentHouseworkCategory]
    let saveAsFrequentState: RegisterHouseworkDraft.SaveAsFrequentState
    /// 繰り返しを設定できるか（テンプレートの読み込みが終わっているか）
    let canSetRecurrence: Bool
    let history: [HouseworkEntryHistoryItem]
    let onTapHistory: (HouseworkEntryHistoryItem) -> Void
    /// 上限に達している状態で「いつもの家事に保存する」を押したとき
    let onTapSaveAsFrequentWhenLimitReached: () -> Void

    @FocusState var isShowingKeyboard: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space24) {
                houseworkSection()
                saveAsFrequentSection()
                if !history.isEmpty {
                    entryHistorySection()
                }
            }
            .padding(.space16)
            // 入力欄の下端が、右下に浮く2つのフローティングボタンに隠れないようにする
            .padding(.bottom, .space64 * 2)
        }
        .scrollDismissesKeyboard(.interactively)
    }

}

// MARK: - UI定義

private extension ManualHouseworkForm {

    /// セクションの見出しと、中身をひとまとまりに見せるカード
    /// - Note: 見出しの字下げは、カードの中の文字の位置に揃える
    func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(title)
                .font(with: .boldCaption)
                .foregroundStyle(.onSurfaceVariant)
                .padding(.horizontal, .space16)
            VStack(spacing: .space16) {
                content()
            }
            .sectionCardStyle()
        }
    }

    func houseworkSection() -> some View {
        section("登録する家事") {
            inputTitleField()
            Divider()
            inputPointPicker()
            if canSetRecurrence {
                Divider()
                inputRecurrence()
            }
        }
    }

    func inputTitleField() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("家事の名前")
                .font(with: .body)
                .foregroundStyle(.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            ClearableTextField(
                text: $entry.title,
                placeholder: "家事の名前を入力",
                focus: $isShowingKeyboard
            )
        }
    }

    func inputPointPicker() -> some View {
        HStack(spacing: .space8) {
            Text("完了ポイント")
                .font(with: .body)
                .foregroundStyle(.onSurface)
            Spacer()
            PointWheelPickerField(point: $entry.point)
                .font(with: .body)
        }
    }

    /// - Note: 家事自体はカテゴリを持たないため、カテゴリはいつもの家事に保存するときだけ意味を持つ
    func saveAsFrequentSection() -> some View {
        section("いつもの家事") {
            saveAsFrequentControl()
            Divider()
            categoryPicker()
                .disabled(!entry.savesAsFrequent)
        }
    }

    @ViewBuilder
    func saveAsFrequentControl() -> some View {
        switch saveAsFrequentState {
        case .available:
            Toggle("いつもの家事に保存する", isOn: $entry.savesAsFrequent)
                .font(with: .body)

        case .duplicated:
            VStack(alignment: .leading, spacing: .space4) {
                Toggle("いつもの家事に保存する", isOn: .constant(false))
                    .font(with: .body)
                    .disabled(true)
                Text("同じ名前のいつもの家事があります")
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
            }

        case .limitReached:
            Button {
                onTapSaveAsFrequentWhenLimitReached()
            } label: {
                HStack(spacing: .space8) {
                    Text("いつもの家事に保存する")
                        .font(with: .body)
                        .foregroundStyle(.onSurface)
                    Spacer()
                    Text("無料プランは\(FrequentHouseworkLimitPolicy.freeLimit)件まで")
                        .font(with: .caption)
                        .foregroundStyle(.onSurfaceVariant)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    func categoryPicker() -> some View {
        HStack(spacing: .space8) {
            Text("カテゴリ")
                .font(with: .body)
                .foregroundStyle(.onSurface)
            Spacer()
            Picker("カテゴリ", selection: $entry.categoryId) {
                ForEach(categories) { category in
                    Text(category.name)
                        .tag(category.categoryId)
                }
            }
            .pickerStyle(.menu)
            .tint(.onSurface)
        }
    }

    func inputRecurrence() -> some View {
        RecurrenceSelector(
            input: $entry.recurrenceInput,
            kinds: HouseworkRecurrenceInput.Kind.allCases,
            titleFont: .body,
            showsDetail: false
        )
    }

    /// - Note: 前回登録したときの完了ポイントも一緒に戻すため、名前の横にポイントを添えて何が入るかを示す
    func entryHistorySection() -> some View {
        section("入力履歴") {
            ForEach(Array(history.enumerated()), id: \.element) { index, item in
                if index > 0 {
                    Divider()
                }
                entryHistoryRow(item)
            }
        }
    }

    func entryHistoryRow(_ item: HouseworkEntryHistoryItem) -> some View {
        Button {
            onTapHistory(item)
        } label: {
            HStack(spacing: .space8) {
                Text(item.title)
                    .font(with: .body)
                    .foregroundStyle(.onSurface)
                Spacer()
                Text("\(item.point)pt")
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.title) \(item.point)ポイント")
    }

}

#if DEBUG
#Preview("ManualHouseworkForm_入力なし") {
    ManualHouseworkForm(
        entry: .constant(.initial),
        categories: FrequentHouseworkContext().categories,
        saveAsFrequentState: .available,
        canSetRecurrence: true,
        history: [
            .init(title: "洗濯", point: 20),
            .init(title: "掃除", point: 10),
        ],
        onTapHistory: { _ in },
        onTapSaveAsFrequentWhenLimitReached: {}
    )
}

#Preview("ManualHouseworkForm_名前が重複") {
    ManualHouseworkForm(
        entry: .constant(.init(
            id: "",
            title: "洗濯",
            point: 20,
            categoryId: nil,
            savesAsFrequent: false,
            recurrenceInput: .init(kind: .none)
        )),
        categories: FrequentHouseworkContext().categories,
        saveAsFrequentState: .duplicated,
        canSetRecurrence: true,
        history: [],
        onTapHistory: { _ in },
        onTapSaveAsFrequentWhenLimitReached: {}
    )
}

#Preview("ManualHouseworkForm_毎週くり返し") {
    ManualHouseworkForm(
        entry: .constant(.init(
            id: "",
            title: "ゴミ出し",
            point: 10,
            categoryId: nil,
            savesAsFrequent: false,
            recurrenceInput: .init(kind: .weekly, weekdays: [.thursday])
        )),
        categories: FrequentHouseworkContext().categories,
        saveAsFrequentState: .available,
        canSetRecurrence: true,
        history: [],
        onTapHistory: { _ in },
        onTapSaveAsFrequentWhenLimitReached: {}
    )
}

#Preview("ManualHouseworkForm_毎月くり返し_月末") {
    ManualHouseworkForm(
        entry: .constant(.init(
            id: "",
            title: "排水溝の掃除",
            point: 30,
            categoryId: nil,
            savesAsFrequent: false,
            recurrenceInput: .init(kind: .monthly, dayOfMonth: 31)
        )),
        categories: FrequentHouseworkContext().categories,
        saveAsFrequentState: .available,
        canSetRecurrence: true,
        history: [],
        onTapHistory: { _ in },
        onTapSaveAsFrequentWhenLimitReached: {}
    )
}

#Preview("ManualHouseworkForm_上限に到達") {
    ManualHouseworkForm(
        entry: .constant(.init(
            id: "",
            title: "風呂掃除",
            point: 10,
            categoryId: nil,
            savesAsFrequent: false,
            recurrenceInput: .init(kind: .none)
        )),
        categories: FrequentHouseworkContext().categories,
        saveAsFrequentState: .limitReached,
        canSetRecurrence: false,
        history: [],
        onTapHistory: { _ in },
        onTapSaveAsFrequentWhenLimitReached: {}
    )
}
#endif
