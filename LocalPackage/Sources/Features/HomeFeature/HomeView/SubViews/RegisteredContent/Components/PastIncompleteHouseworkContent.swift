//
//  PastIncompleteHouseworkContent.swift
//  homete
//

import HometeDomain
import HometeUI
import HouseworkFeature
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

/// 「やり残している家事」のUI
///
/// 見出し・日付ごとのカード・広告・読み込み中の表示を、ダッシュボードの`LazyVStack`の要素として並べる。
/// 1つのViewにまとめると、件数が多いときにすべての行を一度に描画してしまうため、`body`は要素を並べるだけにする。
/// 渡された値を描画してタップを伝えるだけで、シートの表示や画面遷移、読み込みは呼び出し側が行う。
struct PastIncompleteHouseworkContent<RowMenu: View, Advertisement: View>: View {

    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale
    @Environment(\.timeZone) var timeZone
    @Environment(\.now) var now

    let list: PastIncompleteHouseworkList
    let showsAdvertisement: Bool
    /// さらに前の家事を読み込んでいる間、末尾にインジケータを出す
    let isLoadingOlder: Bool
    /// さらに前の家事を読み込み終えるたびに変わる値
    ///
    /// 読み込んだ後も末尾が表示されたままなら、もう一度`onAppearEnd`を呼ぶために使う。
    /// 読み込んだ期間にやり残しが無いと一覧が変わらず、末尾が表示され直さないため
    let olderPeriodLoadCount: Int
    let onTapItem: (HouseworkBoardItem) -> Void
    /// 行の完了ボタンのタップ。完了のハーフモーダルは呼び出し側が出す
    let onTapComplete: (HouseworkBoardItem) -> Void
    /// 一覧の末尾が表示されたとき。さらに前の家事を読み込むきっかけにする
    let onAppearEnd: () -> Void
    /// 家事を長押ししたときと、その他ボタンのメニューの中身
    @ViewBuilder let rowMenu: (HouseworkBoardItem) -> RowMenu
    /// 日付の区切りの間に挟む広告。引数は何番目の広告か
    @ViewBuilder let advertisement: (Int) -> Advertisement

    var body: some View {
        if !list.sections.isEmpty {
            titleText
            ForEach(list.elements(showsAdvertisement: showsAdvertisement)) { element in
                switch element {
                case let .section(section):
                    daySection(section)
                        .sectionCardStyle()

                case let .advertisement(index):
                    // AdMobのガイドラインに沿って、誤タップを防ぐためにタップできる行から広告を離す
                    advertisement(index)
                        .padding(.vertical, .space8)
                }
            }
            endContent
        }
    }

}

// MARK: - UI定義

private extension PastIncompleteHouseworkContent {

    var titleText: some View {
        Text("やり残している家事", bundle: #bundle)
            .font(with: .headLineM)
            .foregroundStyle(.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, .space8)
            .accessibilityAddTraits(.isHeader)
    }

    func daySection(_ section: PastIncompleteHouseworkList.DaySection) -> some View {
        VStack(spacing: .space16) {
            HStack(alignment: .firstTextBaseline) {
                Text(dateText(section.date))
                    .font(with: .headLineS)
                    .foregroundStyle(.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(section.items.count)件", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
            }
            ForEach(section.items) { item in
                houseworkItemRow(item)
                    .contextMenu {
                        rowMenu(item)
                    }
            }
        }
    }

    func houseworkItemRow(_ item: HouseworkBoardItem) -> some View {
        HouseBoardListRow(
            houseworkItem: item.originalItem,
            // 未完了の家事には担当者もありがとうも無いので、完了リスト向けの表示は渡さない
            completionInfo: nil,
            showsCompleteButton: true,
            // 未完了の家事だけを並べるため、必ず「完了にする」「やらない」が出る
            showsMoreButton: true,
            onTapRow: { onTapItem(item) },
            onTapThanks: nil,
            onTapComplete: { onTapComplete(item) },
            menuContent: { rowMenu(item) }
        )
    }

    /// 末尾が表示されたことを伝え、読み込み中ならインジケータを出す
    var endContent: some View {
        ZStack {
            if isLoadingOlder {
                ProgressView()
                    .padding(.vertical, .space8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 1)
        .task(id: olderPeriodLoadCount) {
            onAppearEnd()
        }
    }

    /// 日付と、今日から何日前か（例: 10月27日（2日前））
    func dateText(_ date: Date) -> LocalizedStringResource {
        let format = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: timeZone)
            .month()
            .day()
        let dateText = date.formatted(format)
        let today = calendar.startOfDay(for: now)
        let daysAgo = calendar.dateComponents([.day], from: date, to: today).day ?? 0
        if daysAgo == 1 {
            return .localized("\(dateText)（昨日）", comment: "やり残している家事の日付の区切り。昨日の日付（例: 10月28日）")
        }
        return .localized(
            "\(dateText)（\(daysAgo)日前）",
            comment: "やり残している家事の日付の区切り。1つめは日付（例: 10月27日）、2つめは今日から何日前か"
        )
    }

}

#if DEBUG
#Preview("PastIncompleteHouseworkContent_日付1つ") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    ScrollView {
        LazyVStack(spacing: .space24) {
            PastIncompleteHouseworkContent(
                list: .make(
                    storedAllItems: .makeForPastIncompletePreview(today: today, daysAgo: [1]),
                    now: today,
                    calendar: .japanese
                ),
                showsAdvertisement: false,
                isLoadingOlder: false,
                olderPeriodLoadCount: 0,
                onTapItem: { _ in },
                onTapComplete: { _ in },
                onAppearEnd: {},
                rowMenu: { _ in EmptyView() },
                advertisement: { _ in EmptyView() }
            )
        }
        .padding(.horizontal, .space16)
    }
    .setupEnvironmentForPreview()
    .environment(\.now, .previewDate(year: 2026, month: 5, day: 18))
}

#Preview("PastIncompleteHouseworkContent_広告あり") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    ScrollView {
        LazyVStack(spacing: .space24) {
            PastIncompleteHouseworkContent(
                list: .make(
                    storedAllItems: .makeForPastIncompletePreview(today: today, daysAgo: [1, 2, 5, 9]),
                    now: today,
                    calendar: .japanese
                ),
                showsAdvertisement: true,
                isLoadingOlder: false,
                olderPeriodLoadCount: 0,
                onTapItem: { _ in },
                onTapComplete: { _ in },
                onAppearEnd: {},
                rowMenu: { _ in EmptyView() },
                advertisement: { _ in
                    Text(verbatim: "Advertisement")
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(.gray.opacity(0.3))
                }
            )
        }
        .padding(.horizontal, .space16)
    }
    .setupEnvironmentForPreview()
    .environment(\.now, .previewDate(year: 2026, month: 5, day: 18))
}

// スピナーは撮影ごとに回転角が変わりVRTがフレーキーになるため、スナップショットの対象から外す
#Preview("PastIncompleteHouseworkContent_読み込み中") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    ScrollView {
        LazyVStack(spacing: .space24) {
            PastIncompleteHouseworkContent(
                list: .make(
                    storedAllItems: .makeForPastIncompletePreview(today: today, daysAgo: [3]),
                    now: today,
                    calendar: .japanese
                ),
                showsAdvertisement: false,
                isLoadingOlder: true,
                olderPeriodLoadCount: 0,
                onTapItem: { _ in },
                onTapComplete: { _ in },
                onAppearEnd: {},
                rowMenu: { _ in EmptyView() },
                advertisement: { _ in EmptyView() }
            )
        }
        .padding(.horizontal, .space16)
    }
    .setupEnvironmentForPreview()
    .environment(\.now, .previewDate(year: 2026, month: 5, day: 18))
    #if canImport(Prefire)
        .prefireIgnored()
    #endif
}
#endif
