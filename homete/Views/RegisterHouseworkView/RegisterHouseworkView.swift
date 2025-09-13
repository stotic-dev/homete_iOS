//
//  RegisterHouseworkView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import SwiftUI

struct RegisterHouseworkView: View {
    
    @State var houseworkTitle = ""
    
    @AppStorage(key: .houseworkEntryHistoryList) var houseworkEntryHistoryList = HouseworkHistoryList(items: [])
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: DesignSystem.Space.space16) {
                Spacer()
                    .frame(height: DesignSystem.Space.space24)
                Text("家事を追加")
                    .font(with: .headLineL)
                ZStack {
                    TextField("家事の名前を入力", text: $houseworkTitle)
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
                Text("入力履歴")
                    .font(with: .headLineM)
                List {
                    ForEach(houseworkEntryHistoryList.items, id: \.self) { item in
                        Button(item) {
                            houseworkTitle = item
                            // TODO: 入力履歴の一番上になるよう配列の順番を入れ替える
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .listStyle(.inset)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Space.space16)
            Button {
                // TODO: 入力した家事を登録する
                // TODO: 現在の家事リストの中に同じ家事がある場合はアラートを表示
            } label: {
                Text("登録する")
                    .font(with: .headLineM)
            }
            .floatingButtonStyle(isDisable: houseworkTitle.isEmpty)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding([.trailing, .bottom], DesignSystem.Space.space24)
        }
    }
}

private extension RegisterHouseworkView {
    
    func tappedClearTextFiledButton() {
        
        withAnimation {
            
            houseworkTitle = ""
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
    RegisterHouseworkView()
        .defaultAppStorage(userDefaults)
}
