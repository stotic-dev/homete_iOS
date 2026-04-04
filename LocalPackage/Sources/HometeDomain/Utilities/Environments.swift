//
//  Environments.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/04.
//

import SwiftUI

extension EnvironmentValues {
    /// 現在の日付のDateオブジェクトを返す
    @Entry public var now = Date.now
}
