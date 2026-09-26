//
//  FrequentHouseworkContext+Environment.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

public extension EnvironmentValues {

    /// 所属している同居人グループのいつもの家事
    @Entry var frequentHouseworkContext: FrequentHouseworkContext = .init()

}
