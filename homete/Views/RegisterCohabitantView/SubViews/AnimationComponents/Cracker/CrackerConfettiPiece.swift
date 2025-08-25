//
//  CrackerConfettiPiece.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/23.
//

import SwiftUI

struct CrackerConfettiPiece: Identifiable {
    
    let id: UUID
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var angle: Angle
    var speed: CGFloat
    var isShow: Bool
    
    private static let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .orange, .purple]
    
    static func makeConfettis(startX: CGFloat, startY: CGFloat, count: Int = 100) -> [Self] {
        
        return (0..<count).map { _ in
            
            return .init(
                id: UUID(),
                size: 8,
                x: startX,
                y: startY,
                color: colors.randomElement() ?? .red,
                angle: .degrees(Double.random(in: -50...50)),
                speed: 0.6,
                isShow: true
            )
        }
    }
    
    func explosion(startX: CGFloat, startY: CGFloat) -> Self {
        
        // 周囲に散らす
        let dx = CGFloat.random(in: (startX - 70)...(startX + 120))
        let dy = CGFloat.random(in: (startY - 150)...(startY + 30))
        
        return .init(
            id: id,
            size: size,
            x: dx,
            y: dy,
            color: color,
            angle: angle,
            speed: speed,
            isShow: true
        )
    }
    
    func scatter() -> Self {
        
        // 下に移動しながら消える
        return .init(
            id: id,
            size: size,
            x: x,
            y: y + 50,
            color: color,
            angle: angle,
            speed: speed,
            isShow: false
        )
    }
}
