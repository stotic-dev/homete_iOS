//
//  RegisterHouseworkView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import SwiftUI

struct HouseworkHistoryList: Equatable {
    
    var items: [String]
}

extension HouseworkHistoryList: Codable {
    
    enum CodingKeys: String, CodingKey {
        case items
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode(Array<String>.self, forKey: .items)
    }
}

extension HouseworkHistoryList: RawRepresentable {
    
    init?(rawValue: String) {
        
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(HouseworkHistoryList.self, from: data) else {
            
            return nil
        }
        self = decoded
    }
    
    var rawValue: String {
        
        guard
            let data = try? JSONEncoder().encode(self),
            let jsonString = String(data: data, encoding: .utf8) else {
            
            return ""
        }
        return jsonString
    }
}

struct RegisterHouseworkView: View {
    
    @State var houseworkTitle = ""
    
    @AppStorage(key: .houseworkEntryHistoryList) var houseworkEntryHistoryList = HouseworkHistoryList(items: [])
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.space16) {
            Text("家事を追加")
                .font(with: .headLineL)
            ZStack {
                TextField("家事の名前を入力", text: $houseworkTitle)
                    .foregroundStyle(.primary1)
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
                    Text(item)
                }
            }
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Space.space16)
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
