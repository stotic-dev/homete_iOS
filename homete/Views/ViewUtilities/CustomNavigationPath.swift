//
//  CustomNavigationPath.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/07/26.
//

import SwiftUI

@Observable
final class CustomNavigationPath<Element: Hashable> {
    
    var path: [Element]
    
    init(path: [Element]) {
        self.path = path
    }
    
    func popToRoot() {
        
        path.removeAll()
    }
    
    func pop() {
        
        _ = path.popLast()
    }
}
