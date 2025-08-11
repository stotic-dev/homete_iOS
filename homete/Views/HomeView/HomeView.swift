//
//  HomeView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Space.space24) {
            Image(.suggestPartner)
                .resizable()
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(.radius16)
            VStack(spacing: DesignSystem.Space.space8) {
                Text("まだパートナーが登録されていません")
                    .font(with: .headLineS)
                Text("パートナーを登録して、家事を分担しましょう！")
                    .font(with: .body)
            }
            Button {
                print("tapped register")
            } label: {
                Text("パートナーを登録する")
                    .font(with: .headLineS)
                    .padding(.horizontal, DesignSystem.Space.space16)
                    .padding(.vertical, DesignSystem.Space.space8)
                    .foregroundStyle(Color(.commonBlack))
                    .background {
                        GeometryReader { proxy in
                            RoundedRectangle(cornerRadius: proxy.size.height / 2)
                                .fill(Color(.primary3))
                        }
                    }
            }
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Space.space16)
        .navigationTitle("homete")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    print("tapped settings")
                } label: {
                    Image(systemName: "gearshape")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(DesignSystem.Space.space8)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
