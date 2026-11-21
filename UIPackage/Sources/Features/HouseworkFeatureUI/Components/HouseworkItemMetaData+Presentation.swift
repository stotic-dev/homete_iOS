//
//  HouseworkItemMetaData+Presentation.swift
//  LocalPackage
//

import HometeModel
import HometeResources
import SwiftUI

public extension HouseworkItemMetaData {

    var label: LocalizedStringResource {
        switch self {
        case .completed:
            .localized("完了")
        case .notTodo:
            .localized("やらない")
        }
    }

    var systemImage: String {
        switch self {
        case .completed:
            "checkmark.seal.fill"
        case .notTodo:
            "minus.circle"
        }
    }

    var foregroundStyle: Color {
        switch self {
        case .completed, .notTodo:
            .textPrimary
        }
    }

}
