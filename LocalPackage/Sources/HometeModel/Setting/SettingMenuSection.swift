//
//  SettingMenuSection.swift
//  LocalPackage
//

import Foundation

/// 設定画面のメニューをまとめて表示する区分
/// - Note: ケースの並びが画面での表示順になる
public enum SettingMenuSection: Equatable, CaseIterable, Sendable {

    /// グループのメンバーに関すること
    case group
    /// グループで共有する家事の設定
    case housework
    /// 通知やプランなど、アプリ全体の設定
    case app
    /// 運営への問い合わせ
    case support
    /// 利用規約・ライセンスなど、アプリについての情報
    case about
    #if DEBUG
    case developer
    #endif

}

/// 設定画面で1つの区分にまとめて表示するメニュー
public struct SettingMenuGroup: Identifiable, Equatable, Sendable {

    public let section: SettingMenuSection
    public let items: [SettingMenuItem]

    public init(
        section: SettingMenuSection,
        items: [SettingMenuItem]
    ) {
        self.section = section
        self.items = items
    }

    public var id: SettingMenuSection {
        section
    }

    /// 表示するメニューを区分ごとにまとめる
    /// - Parameter items: 表示するメニュー
    /// - Returns: 区分の表示順に並べたもの。表示するメニューが無い区分は含めない
    public static func make(from items: [SettingMenuItem]) -> [Self] {
        SettingMenuSection.allCases.compactMap { section in
            let sectionItems = items.filter { $0.section == section }
            return sectionItems.isEmpty ? nil : .init(section: section, items: sectionItems)
        }
    }

}
