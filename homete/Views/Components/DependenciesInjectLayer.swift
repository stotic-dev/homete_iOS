//
//  DependenciesInjectLayer.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/27.
//

import SwiftUI

struct DependenciesInjectLayer<Content: View>: View {
    
    @Environment(\.appDependencies) var appDependencies
    let content: (AppDependencies) -> Content
    
    init(@ViewBuilder content: @escaping (AppDependencies) -> Content) {
        
        self.content = content
    }
    
    var body: some View {
        content(appDependencies)
    }
}
