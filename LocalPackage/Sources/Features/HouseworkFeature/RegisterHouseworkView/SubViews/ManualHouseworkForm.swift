//
//  ManualHouseworkForm.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事の登録シートの「新しく入力」タブ
struct ManualHouseworkForm: View {

    @Binding var entry: RegisterHouseworkDraft.ManualEntry

    /// 「いつもの家事に保存する」で選べるカテゴリ
    let categories: [FrequentHouseworkCategory]
    let saveAsFrequentState: RegisterHouseworkDraft.SaveAsFrequentState
    /// 繰り返しを設定できるか（テンプレートの読み込みが終わっているか）
    let canSetRecurrence: Bool
    /// 「続けて入力する」を押せるか
    let canQueue: Bool
    let history: [String]
    let onTapQueue: () -> Void
    let onTapHistory: (String) -> Void
    /// 上限に達している状態で「いつもの家事に保存する」を押したとき
    let onTapSaveAsFrequentWhenLimitReached: () -> Void

    @FocusState var isShowingKeyboard: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space16) {
                inputTitleField()
                inputPointPicker()
                saveAsFrequentSection()
                if canSetRecurrence {
                    inputRecurrence()
                }
                queueButton()
                if !history.isEmpty {
                    entryHistoryContent()
                }
            }
            .padding(.horizontal, .space16)
            .padding(.bottom, .space16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

}

// MARK: - UI定義

private extension ManualHouseworkForm {

    func inputTitleField() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("家事の名前")
                .font(with: .headLineS)
            ClearableTextField(
                text: $entry.title,
                placeholder: "家事の名前を入力",
                focus: $isShowingKeyboard
            )
        }
    }

    func inputPointPicker() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("完了ポイント")
                .font(with: .headLineS)
            PointWheelPickerField(point: $entry.point)
                .font(with: .headLineM)
        }
    }

    /// - Note: 家事自体はカテゴリを持たないため、カテゴリはいつもの家事に保存するときだけ意味を持つ
    func saveAsFrequentSection() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            saveAsFrequentControl()
            categoryPicker()
                .disabled(!entry.savesAsFrequent)
        }
    }

    @ViewBuilder
    func saveAsFrequentControl() -> some View {
        switch saveAsFrequentState {
        case .available:
            Toggle("いつもの家事に保存する", isOn: $entry.savesAsFrequent)
                .font(with: .headLineS)

        case .duplicated:
            VStack(alignment: .leading, spacing: .space4) {
                Toggle("いつもの家事に保存する", isOn: .constant(false))
                    .font(with: .headLineS)
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
                        .font(with: .headLineS)
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
                .font(with: .headLineS)
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
            titleFont: .headLineS,
            showsDetail: false
        )
    }

    func queueButton() -> some View {
        Button("続けて入力する") {
            onTapQueue()
        }
        .subPrimaryButtonStyle()
        .disabled(!canQueue)
        .frame(maxWidth: .infinity)
    }

    func entryHistoryContent() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("入力履歴")
                .font(with: .headLineS)
            ForEach(history, id: \.self) { item in
                Button(item) {
                    onTapHistory(item)
                }
                .font(with: .body)
                .foregroundStyle(.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

}

#if DEBUG
#Preview("ManualHouseworkForm_入力なし") {
    ManualHouseworkForm(
        entry: .constant(.initial),
        categories: FrequentHouseworkContext().categories,
        saveAsFrequentState: .available,
        canSetRecurrence: true,
        canQueue: false,
        history: ["洗濯", "掃除"],
        onTapQueue: {},
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
        canQueue: true,
        history: [],
        onTapQueue: {},
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
        canQueue: true,
        history: [],
        onTapQueue: {},
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
        canQueue: true,
        history: [],
        onTapQueue: {},
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
        canQueue: true,
        history: [],
        onTapQueue: {},
        onTapHistory: { _ in },
        onTapSaveAsFrequentWhenLimitReached: {}
    )
}
#endif
