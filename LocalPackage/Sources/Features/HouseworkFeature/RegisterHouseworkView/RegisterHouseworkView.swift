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
    @Environment(\.loginContext.cohabitantId) var cohabitantId
    @LoadingState var loadingState

    @State var houseworkTitle = ""
    @State var completePoint = 10
    @State var isPresentingDuplicationAlert = false

    @FocusState var isShowingKeyboard: Bool
    @CommonError var commonErrorContent

    @AppStorage(key: .houseworkEntryHistoryList) var houseworkEntryHistoryList = HouseworkHistoryList(items: [])

    let dailyHouseworkList: DailyHouseworkList

    public static func make(dailyHouseworkList: DailyHouseworkList) -> some View {
        RegisterHouseworkView(dailyHouseworkList: dailyHouseworkList)
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
            .disabled(houseworkTitle.isEmpty)
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

    func tappedEntryHistoryRow(_ item: String) {
        houseworkTitle = item
        houseworkEntryHistoryList.moveToFrontIfExists(item)
    }

    func tappedRegisterButton() async {
        guard let cohabitantId else { return }

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
                cohabitantId: cohabitantId
            )
            dismiss()
        } catch {
            print("Failed registering a new housework item: \(error)")
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
        )
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
        )
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
