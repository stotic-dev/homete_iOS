//
//  Storable.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/19.
//

import SwiftUI

@MainActor
protocol Storable: AnyObject, Observable {
    
    init(appDependencies: AppDependencies)
}
