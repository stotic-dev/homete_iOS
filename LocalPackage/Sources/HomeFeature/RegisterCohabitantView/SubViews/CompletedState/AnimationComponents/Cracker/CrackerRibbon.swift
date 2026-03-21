//
//  CrackerRibbon.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/23.
//

import SwiftUI

struct CrackerRibbon: Identifiable {
    
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var angle: Angle
    var speed: CGFloat
    var opacity: CGFloat
    
    private static let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .orange, .purple]
    
    static func makeRibbons(startX: CGFloat, startY: CGFloat, count: Int = 25) -> [Self] {
        
        return (0..<count).map { _ in
            
            return .init(
                id: UUID(),
                x: startX,
                y: startY,
                color: colors.randomElement() ?? .red,
                angle: .degrees(Double.random(in: -10...50)),
                speed: Double.random(in: 0.5...1),
                opacity: 1
            )
        }
    }
    
    func explosion() -> Self {
        
        // 設定されている角度に応じた方向に飛ばす
        return .init(
            id: id,
            x: angle.degrees * 10,
            y: 0,
            color: color,
            angle: angle,
            speed: speed,
            opacity: opacity
        )
    }
    
    func scatter() -> Self {
        
        // 消える
        return .init(
            id: id,
            x: x,
            y: y,
            color: color,
            angle: angle,
            speed: speed,
            opacity: 0
        )
    }
}
