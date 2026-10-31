//
//  HouseworkDetailView+Postpone.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 「別の日にまわす…」から開く、まわす日を選ぶカレンダーと、選んだ日へまわす処理
extension HouseworkDetailView {

    func postponeDatePicker() -> some View {
        NavigationStack {
            HouseworkPostponeDatePickerView(
                dateRange: .init(itemDate: item.originalItem.indexedDate.value, now: now, calendar: calendar),
                onSelect: { selectedPostponeDate($0) },
                onTapClose: { isPresentedPostponeDatePicker = false }
            )
        }
        .presentationDragIndicator(.visible)
        .trackScreenView(.houseworkPostponeDatePicker)
    }

    func selectedPostponeDate(_ date: Date) {
        pendingPostponeDate = date
        isPresentedPostponeDatePicker = false
    }

    func dismissedPostponeDatePicker() {
        guard let date = pendingPostponeDate else { return }
        pendingPostponeDate = nil
        guard let cohabitantId = account.cohabitantId else { return }

        let target = item
        loadingState.task {
            do {
                let result = try await houseworkListStore.postponeIfNeeded(
                    target,
                    to: date,
                    templateContext: templateContext,
                    storagePolicy: storagePolicy,
                    cohabitantId: cohabitantId,
                    step: .detail
                )
                switch result {
                case .postponed:
                    // まわした家事はこの日の一覧から消えるため、詳細を閉じて家事ボードへ戻る
                    dismiss()

                case let .needsConfirmation(confirmation):
                    postponeConfirmation = confirmation

                case .skipped:
                    break
                }
            } catch {
                commonErrorContent = .init(error: error)
            }
        }
    }

}
