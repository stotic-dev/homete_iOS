//
//  HouseworkTemplateContext.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/14.
//

import Foundation

public struct HouseworkTemplateContext {

    public let metadata: HouseworkTemplateMeta?
    public let houseworkTemplate: [HouseworkTemplateDay]

    /// テンプレートが設定されているかどうか
    public var hasTemplate: Bool {
        metadata != nil
    }

    public init(metadata: HouseworkTemplateMeta?, houseworkTemplate: [HouseworkTemplateDay]) {
        self.metadata = metadata
        self.houseworkTemplate = houseworkTemplate
    }

    /// 指定日付のテンプレートを返す
    public func templateOfDay(by date: Date, calendar: Calendar) -> HouseworkTemplateDay? {
        houseworkTemplate.first {
            (calendar.component(.weekday, from: date) - 1) == $0.dayOfWeek
        }
    }

}
