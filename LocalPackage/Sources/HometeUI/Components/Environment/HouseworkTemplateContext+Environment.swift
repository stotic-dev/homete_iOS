//
//  HouseworkTemplateContext+Environment.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/14.
//

import HometeDomain
import SwiftUI

public extension EnvironmentValues {

    /// 現在洗濯中のテンプレートのコンテキスト
    @Entry var houseworkTemplateContext: HouseworkTemplateContext = .init(houseworkTemplate: [])

}
