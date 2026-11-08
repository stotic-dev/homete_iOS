//
//  InquiryListScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SettingFeatureUI
import SwiftUI

/// 問い合わせの一覧画面
///
/// 設定画面と同じ`InquiryListStore`を使い、ここでの取得結果を導線のバッジにも反映する。
struct InquiryListScreen: View {

    @Environment(InquiryListStore.self) var inquiryListStore
    @Environment(\.settingNavigationPath) var navigationPath

    @State var isShowCreation = false

    var body: some View {
        InquiryListView(
            state: inquiryListStore.state,
            onTapCreate: { isShowCreation = true },
            onTapInquiry: { inquiry in navigationPath.push(.inquiryDetail(inquiryId: inquiry.id)) },
            onReachEnd: { loadMore() },
            onRefresh: { await inquiryListStore.refresh() },
            onTapRetry: { refresh() }
        )
        .task {
            // 詳細から戻ったときにも、対応状況の変化を取り直す
            await inquiryListStore.refresh()
        }
        .sheet(isPresented: $isShowCreation) {
            InquiryCreationScreen.make { inquiry in
                createdInquiry(inquiry)
            }
        }
        .trackScreenView(.inquiryList)
    }

}

// MARK: - プレゼンテーションロジック

private extension InquiryListScreen {

    func loadMore() {
        Task {
            await inquiryListStore.loadMore()
        }
    }

    func refresh() {
        Task {
            await inquiryListStore.refresh()
        }
    }

    /// 作った問い合わせを一覧に足し、続けてやりとりできるよう詳細を開く
    func createdInquiry(_ inquiry: Inquiry) {
        inquiryListStore.apply(inquiry)
        navigationPath.push(.inquiryDetail(inquiryId: inquiry.id))
    }

}
