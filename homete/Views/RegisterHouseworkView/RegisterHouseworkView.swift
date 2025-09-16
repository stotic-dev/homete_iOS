//
//  RegisterHouseworkView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import FirebaseFunctions
import SwiftUI

struct RegisterHouseworkView: View {
    
    @Environment(\.appDependencies.houseworkClient) var houseworkClient
    @Environment(\.cohabitantId) var cohabitantId
    @Environment(\.dismiss) var dismiss
    
    @State var houseworkTitle = ""
    @State var isPresentingDuplicationAlert = false
    @State var isPresentingCommonErrorAlert = false
    @State var domainError: DomainError?
    @State var isLoading = false
    
    @FocusState var isShowingKeyboard: Bool
    
    @AppStorage(key: .houseworkEntryHistoryList) var houseworkEntryHistoryList = HouseworkHistoryList(items: [])
    
    let dailyHouseworkList: DailyHouseworkList
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: DesignSystem.Space.space16) {
                Spacer()
                    .frame(height: DesignSystem.Space.space24)
                Text("家事を追加")
                    .font(with: .headLineL)
                inputTextField()
                entryHistoryContent()
                    .opacity(houseworkEntryHistoryList.hasHistory ? 1 : 0)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Space.space16)
            if isShowingKeyboard {
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isShowingKeyboard = false
                    }
            }
            Button {
                Task {
                    await tappedRegisterButton()
                }
            } label: {
                Text("登録する")
                    .font(with: .headLineM)
            }
            .floatingButtonStyle(isDisable: houseworkTitle.isEmpty)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding([.trailing, .bottom], DesignSystem.Space.space24)
            LoadingIndicator()
                .ignoresSafeArea()
                .opacity(isLoading ? 1 : 0)
        }
        .commonError(isPresented: $isPresentingCommonErrorAlert, error: $domainError)
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
        ZStack {
            TextField(
                "",
                text: $houseworkTitle,
                prompt: Text("家事の名前を入力")
                    .foregroundStyle(.primary2.opacity(0.7))
            )
            .focused($isShowingKeyboard)
            .foregroundStyle(.primary2)
            .padding()
            .font(with: .body)
            .background {
                RoundedRectangle(radius: .radius8)
                    .foregroundStyle(.primary3)
            }
            Button {
                tappedClearTextFiledButton()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.primary2)
                    .padding(DesignSystem.Space.space8)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, DesignSystem.Space.space8)
            .opacity(houseworkTitle.isEmpty ? 0 : 1)
        }
    }
    
    func entryHistoryContent() -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.space16) {
            Text("入力履歴")
                .font(with: .headLineM)
            List {
                ForEach(houseworkEntryHistoryList.items, id: \.self) { item in
                    Button(item) {
                        tappedEntryHistoryRow(item)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .listStyle(.inset)
        }
    }
}

// MARK: - プレゼンテーションロジック

private extension RegisterHouseworkView {
    
    func tappedClearTextFiledButton() {
        
        withAnimation {
            
            houseworkTitle = ""
        }
    }
    
    func tappedEntryHistoryRow(_ item: String) {
        
        houseworkTitle = item
        houseworkEntryHistoryList.moveToFrontIfExists(item)
    }
    
    func tappedRegisterButton() async {
        
        withAnimation {
            
            isLoading = true
        }
        
        defer {
            
            withAnimation {
                
                isLoading = false
            }
        }
        
        let newItem = HouseworkItem(
            id: UUID().uuidString,
            title: houseworkTitle,
            state: .incomplete
        )
        
        guard !dailyHouseworkList.isAlreadyRegistered(newItem) else {
            
            isPresentingDuplicationAlert = true
            return
        }
        
        houseworkEntryHistoryList.addNewHistory(houseworkTitle)
        
        do {
            
            // 既に選択日付の家事情報の登録ができている場合は新規家事レコードだけ保存する
            // そうでない場合は、家事情報のレコードも保存する
            if dailyHouseworkList.isRegistered {
                
                try await houseworkClient.registerNewItem(
                    newItem,
                    dailyHouseworkList.indexedDate,
                    cohabitantId
                )
            }
            else {
                
                try await houseworkClient.registerDailyHouseworkList(
                    .init(
                        indexedDate: dailyHouseworkList.indexedDate,
                        metaData: dailyHouseworkList.metaData,
                        items: [newItem]
                    ),
                    cohabitantId
                )
            }
            
            _ = try? await Functions.functions()
                .httpsCallable("notifyothercohabitants")
                .call([
                    "cohabitantId": cohabitantId,
                    "title": "新しい家事が登録されました",
                    "body": houseworkTitle
                ])
            
            dismiss()
        }
        catch {
            
            print("Failed registering a new housework item: \(error)")
            domainError = .other
        }
    }
}

#Preview {
    var userDefaults: UserDefaults {
        // swiftlint:disable:next force_unwrapping
        let userDefaults = UserDefaults(suiteName: "preview")!
        let data = HouseworkHistoryList(items: [
            "洗濯",
            "洗い物",
            "掃除"
        ])
        userDefaults.set(
            data.rawValue,
            forKey: AppStorageCustomTypeKey.houseworkEntryHistoryList.rawValue
        )
        return userDefaults
    }
    RegisterHouseworkView(
        dailyHouseworkList: .init(
            indexedDate: .now,
            metaData: .init(expiredAt: .now),
            items: []
        )
    )
    .defaultAppStorage(userDefaults)
}

#Preview("重複アラート表示") {
    RegisterHouseworkView(
        houseworkTitle: "洗濯",
        isPresentingDuplicationAlert: true,
        dailyHouseworkList: .init(
            indexedDate: .now,
            metaData: .init(expiredAt: .now),
            items: []
        )
    )
}

#Preview("通信中") {
    RegisterHouseworkView(
        isLoading: true,
        dailyHouseworkList: .init(
            indexedDate: .now,
            metaData: .init(expiredAt: .now),
            items: []
        )
    )
}
