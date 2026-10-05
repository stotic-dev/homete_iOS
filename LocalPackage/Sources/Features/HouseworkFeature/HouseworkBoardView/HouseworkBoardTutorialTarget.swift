//
//  HouseworkBoardTutorialTarget.swift
//  LocalPackage
//

import HometeUI

/// 家事ボードのうち、チュートリアルでハイライトするUI
public extension TutorialSpotlightID {

    /// 家事を追加するボタン
    static let houseworkAddButton = Self("housework_add_button")
    /// 未完了の一覧の先頭の家事
    static let houseworkIncompleteRow = Self("housework_incomplete_row")
    /// 完了した家事にありがとうを伝えるハート
    static let houseworkThanksButton = Self("housework_thanks_button")
    /// 複数選択モードに入るナビゲーションバーのボタン
    static let houseworkSelectButton = Self("housework_select_button")
    /// 家事テンプレートを開くナビゲーションバーのボタン
    static let houseworkTemplateButton = Self("housework_template_button")

}
