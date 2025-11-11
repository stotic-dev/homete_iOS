//
//  RegisterHouseworkView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import FirebaseFunctions
import Prefire
import SwiftUI

struct RegisterHouseworkView: View {
    
    @Environment(\.appDependencies.houseworkClient) var houseworkClient
    @Environment(\.cohabitantId) var cohabitantId
    @Environment(\.dismiss) var dismiss
    
    @State var houseworkTitle = ""
    @State var completePoint = 10.0
    @State var isPresentingDuplicationAlert = false
    @State var commonErrorContent: DomainErrorAlertContent = .initial
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
                inputPointSlider()
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
            Button("登録する") {
                Task {
                    await tappedRegisterButton()
                }
            }
            .font(with: .headLineM)
            .floatingButtonStyle(isDisable: houseworkTitle.isEmpty)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding([.trailing, .bottom], DesignSystem.Space.space24)
            LoadingIndicator()
                .ignoresSafeArea()
                .opacity(isLoading ? 1 : 0)
        }
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
    
    func inputPointSlider() -> some View {
        VStack(spacing: DesignSystem.Space.space8) {
            Text("完了ポイント")
                .font(with: .headLineM)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(Int(completePoint).formatted())
                .font(with: .headLineL)
            Slider(value: $completePoint, in: 1...100, step: Double.Stride(1))
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
                    .font(with: .body)
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
            point: Int(completePoint),
            metaData: dailyHouseworkList.metaData
        )
        
        guard !dailyHouseworkList.isAlreadyRegistered(newItem) else {
            
            isPresentingDuplicationAlert = true
            return
        }
        
        houseworkEntryHistoryList.addNewHistory(houseworkTitle)
        
        do {
            
            try await houseworkClient.insertOrUpdateItem(newItem, cohabitantId)
            
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
            commonErrorContent = .init(error: error)
        }
    }
}

#Preview("RegisterHouseworkView") {
    RegisterHouseworkView(
        dailyHouseworkList: .init(
            items: [],
            metaData: .init(indexedDate: .now, expiredAt: .now)
        )
    )
    .injectAppStorageWithPreview("RegisterHouseworkView") { userDefaults in
        let historyList = HouseworkHistoryList(items: [
            "洗濯", "掃除"
        ])
        userDefaults.setValue(historyList.rawValue, forKey: "houseworkEntryHistoryList")
    }
}

#Preview("RegisterHouseworkView_通信中") {
    RegisterHouseworkView(
        isLoading: true,
        dailyHouseworkList: .init(
            items: [],
            metaData: .init(indexedDate: .now, expiredAt: .now)
        )
    )
}
