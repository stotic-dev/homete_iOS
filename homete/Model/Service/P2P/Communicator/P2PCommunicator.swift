//
//  P2PCommunicator.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/26.
//

import SwiftUI

struct P2PCommunicator<Content: View>: View {
    
    let content: () -> Content
    
    init(
        @ViewBuilder content: @escaping () -> Content
    ) {
        
        self.content = content
    }
    
    var body: some View {
        content()
    }
}
