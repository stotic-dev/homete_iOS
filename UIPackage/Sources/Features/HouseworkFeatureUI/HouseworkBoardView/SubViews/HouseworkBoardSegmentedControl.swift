//
//  HouseworkBoardSegmentedControl.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import HometeModel
import SwiftUI

public struct HouseworkBoardSegmentedControl: View {

    @Binding var selectedHouseworkState: HouseworkState

    public init(
        selectedHouseworkState: Binding<HouseworkState>
    ) {
        _selectedHouseworkState = selectedHouseworkState
    }

    public var body: some View {
        Picker("", selection: $selectedHouseworkState) {
            ForEach(HouseworkState.pageableCases) { state in
                Text(state.segmentTitle).tag(state)
            }
        }
        .pickerStyle(.segmented)
    }

}

public extension HouseworkState {

    /// セグメント/ページャーの表示対象とする状態一覧（notTodoはボードから除外済みのため対象外）
    static var pageableCases: [HouseworkState] {
        [.incomplete, .completed]
    }

    var segmentTitle: LocalizedStringResource {
        switch self {
        case .incomplete: .localized("未完了")
        case .completed: .localized("完了")
        case .notTodo: .localized("やらない")
        }
    }

}
