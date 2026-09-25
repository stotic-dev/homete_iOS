//
//  RegisterHouseworkView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

public struct RegisterHouseworkView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(HouseworkListStore.self) var houseworkListStore
    /// 同居人グループに未所属などで用意されていない場合は`nil`
    @Environment(HouseworkTemplateListStore.self) var houseworkTemplateListStore: HouseworkTemplateListStore?
    @Environment(\.loginContext.cohabitantId) var cohabitantId
    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    @LoadingState var loadingState

    @State var houseworkTitle = ""
    @State var completePoint = 10
    @State var recurrenceInput = HouseworkRecurrenceInput(kind: .none)
    @State var isPresentingDuplicationAlert = false

    @FocusState var isShowingKeyboard: Bool
    @CommonError var commonErrorContent

    @AppStorage(key: .houseworkEntryHistoryList) var houseworkEntryHistoryList = HouseworkHistoryList(items: [])

    let dailyHouseworkList: DailyHouseworkList
    let step: HouseworkAnalyticsStep

    public static func make(dailyHouseworkList: DailyHouseworkList, step: HouseworkAnalyticsStep) -> some View {
        RegisterHouseworkView(dailyHouseworkList: dailyHouseworkList, step: step)
    }

    public var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: .space16) {
                Spacer()
                    .frame(height: .space24)
                Text("家事を追加")
                    .font(with: .headLineL)
                inputTextField()
                inputPointPicker()
                if canSetRecurrence {
                    inputRecurrence()
                }
                entryHistoryContent()
                    .opacity(houseworkEntryHistoryList.hasHistory ? 1 : 0)
                Spacer()
            }
            .padding(.horizontal, .space16)
            if isShowingKeyboard {
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isShowingKeyboard = false
                    }
            }
            Button("登録する") {
                loadingState.task {
                    await tappedRegisterButton()
                }
            }
            .font(with: .headLineM)
            .floatingButtonStyle()
            .disabled(houseworkTitle.isEmpty || !recurrenceInput.isValid)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding([.trailing, .bottom], .space24)
        }
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $commonErrorContent)
        .alert("登録できません", isPresented: $isPresentingDuplicationAlert) {
            Button(
                role: .cancel,
                action: {},
                label: { Text("閉じる") }
            )
        } message: {
            Text("\"\(houseworkTitle)\"は既に登録されています。")
        }
        .onAppear {
            onAppear()
        }
        .trackScreenView(.houseworkRegister)
    }

}

// MARK: - コンポーネント

private extension RegisterHouseworkView {

    func inputTextField() -> some View {
        ClearableTextField(
            text: $houseworkTitle,
            placeholder: "家事の名前を入力",
            focus: $isShowingKeyboard
        )
    }

    func inputPointPicker() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("完了ポイント")
                .font(with: .headLineM)
            PointWheelPickerField(point: $completePoint)
                .font(with: .headLineL)
        }
    }

    func inputRecurrence() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("くり返し")
                .font(with: .headLineM)
            RecurrenceSelector(input: $recurrenceInput, kinds: HouseworkRecurrenceInput.Kind.allCases)
            if recurrenceInput.kind != .none {
                Text("家事テンプレートに登録され、今日以降の該当する日に表示されます")
                    .font(with: .caption)
                    .foregroundStyle(.onSubSurface)
            }
        }
    }

    func entryHistoryContent() -> some View {
        VStack(alignment: .leading, spacing: .space16) {
            Text("入力履歴")
                .font(with: .headLineM)
            List {
                ForEach(houseworkEntryHistoryList.items, id: \.self) { item in
                    Button(item) {
                        tappedEntryHistoryRow(item)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(with: .body)
                }
            }
            .listStyle(.inset)
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension RegisterHouseworkView {

    /// 繰り返しを設定できるか
    /// - Note: テンプレートの読み込み中・読み込み失敗時は、既存のテンプレートの有無が分からず重複して作成しかねないので設定させない
    var canSetRecurrence: Bool {
        houseworkTemplateListStore?.loadState == .loaded
    }

    func tappedEntryHistoryRow(_ item: String) {
        houseworkTitle = item
        houseworkEntryHistoryList.moveToFrontIfExists(item)
    }

    func onAppear() {
        // 繰り返しの各種類の初期値は、登録しようとしている日の曜日・日付にしておく
        recurrenceInput = .init(
            kind: recurrenceInput.kind,
            basedOn: dailyHouseworkList.metaData.indexedDate.value,
            calendar: calendar
        )
    }

    func tappedRegisterButton() async {
        guard let cohabitantId else { return }

        if let recurrence = recurrenceInput.recurrence,
           let houseworkTemplateListStore {
            await registerRecurringHousework(
                recurrence: recurrence,
                templateListStore: houseworkTemplateListStore,
                cohabitantId: cohabitantId
            )
            return
        }

        let newItem = HouseworkItem(
            id: UUID().uuidString,
            title: houseworkTitle,
            point: completePoint,
            metaData: dailyHouseworkList.metaData
        )

        guard !dailyHouseworkList.isAlreadyRegistered(newItem) else {
            isPresentingDuplicationAlert = true
            return
        }

        houseworkEntryHistoryList.addNewHistory(houseworkTitle)

        do {
            try await houseworkListStore.register(
                newItem: newItem,
                cohabitantId: cohabitantId,
                step: step
            )
            dismiss()
        } catch {
            print("Failed registering a new housework item: \(error)")
            commonErrorContent = .init(error: error)
        }
    }

    /// 繰り返しを設定した家事は、その日の家事としては登録せずテンプレートに追加する（該当日に仮想表示される）
    func registerRecurringHousework(
        recurrence: HouseworkRecurrence,
        templateListStore: HouseworkTemplateListStore,
        cohabitantId: String
    ) async {
        let newItem = HouseworkTemplateItem(
            id: .init(uuid: UUID()),
            title: houseworkTitle,
            point: completePoint,
            updatedAt: now
        )

        houseworkEntryHistoryList.addNewHistory(houseworkTitle)

        do {
            try await templateListStore.appendItemCreatingTemplateIfNeeded(
                newItem,
                recurrence: recurrence,
                cohabitantId: cohabitantId,
                newTemplateId: UUID().uuidString
            )
            dismiss()
        } catch {
            print("Failed registering a recurring housework item: \(error)")
            commonErrorContent = .init(error: error)
        }
    }

}

#if DEBUG
#Preview("RegisterHouseworkView") {
    RegisterHouseworkView(
        dailyHouseworkList: .init(
            items: [],
            metaData: .init(
                indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
                expiredAt: .now
            )
        ),
        step: .board
    )
    .injectAppStorageWithPreview("RegisterHouseworkView") { userDefaults in
        let historyList = HouseworkHistoryList(items: [
            "洗濯", "掃除",
        ])
        userDefaults.setValue(historyList.rawValue, forKey: "houseworkEntryHistoryList")
    }
    .environment(HouseworkListStore(
        houseworkClient: .previewValue,
        cohabitantPushNotificationClient: .previewValue
    ))
    .environment(HouseworkTemplateListStore(loadState: .loaded))
    #if canImport(Prefire)
        .snapshot(perceptualPrecision: 0.95)
    #endif
}

#Preview("RegisterHouseworkView_毎週くり返し") {
    RegisterHouseworkView(
        recurrenceInput: .init(kind: .weekly, weekdays: [.thursday]),
        dailyHouseworkList: .init(
            items: [],
            metaData: .init(
                indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
                expiredAt: .now
            )
        ),
        step: .board
    )
    .environment(HouseworkListStore(
        houseworkClient: .previewValue,
        cohabitantPushNotificationClient: .previewValue
    ))
    .environment(HouseworkTemplateListStore(loadState: .loaded))
    #if canImport(Prefire)
        .snapshot(perceptualPrecision: 0.95)
    #endif
}

#Preview("RegisterHouseworkView_通信中") {
    RegisterHouseworkView(
        loadingState: .init(store: .init(isLoading: true)),
        dailyHouseworkList: .init(
            items: [],
            metaData: .init(
                indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
                expiredAt: .now
            )
        ),
        step: .board
    )
    .environment(HouseworkListStore(
        houseworkClient: .previewValue,
        cohabitantPushNotificationClient: .previewValue
    ))
    #if canImport(Prefire)
    .prefireIgnored()
    #endif
}
#endif
