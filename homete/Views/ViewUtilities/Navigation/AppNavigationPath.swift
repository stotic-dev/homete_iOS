//
//  AppNavigationPath.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/07/26.
//

import SwiftUI

@Observable
final class AppNavigationPath {
    
    var path: [AppNavigationElement]
    
    init(path: [AppNavigationElement]) {
        self.path = path
    }
    
    func popToRoot() {
        
        path.removeAll()
    }
    
    func pop() {
        
        _ = path.popLast()
    }
    
    func push(_ element: AppNavigationElement) {
        
        path.append(element)
    }
}

extension EnvironmentValues {
    @Entry var appNavigationPath = AppNavigationPath(path: [])
}
