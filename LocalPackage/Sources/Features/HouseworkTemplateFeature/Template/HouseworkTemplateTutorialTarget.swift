//
//  HouseworkTemplateTutorialTarget.swift
//  LocalPackage
//

import HometeUI

/// 家事テンプレート画面のうち、チュートリアルでハイライトするUI
extension TutorialSpotlightID {

    /// 「テンプレートを作成する」ボタン
    static let houseworkTemplateCreateButton = Self("housework_template_create_button")
    /// 家事を追加するボタン
    static let houseworkTemplateAddButton = Self("housework_template_add_button")
    /// 先頭の曜日のセクション
    static let houseworkTemplateFirstDaySection = Self("housework_template_first_day_section")
    /// ナビゲーションバー。保存ボタンはバーに1つだけ置いていて位置を測れないため、バーごと切り抜く
    static let houseworkTemplateNavigationBar = Self("housework_template_navigation_bar")

}
