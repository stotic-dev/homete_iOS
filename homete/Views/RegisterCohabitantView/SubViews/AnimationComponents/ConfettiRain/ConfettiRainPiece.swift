//
//  ConfettiRainPiece.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/25.
//

import SwiftUI

struct ConfettiRainPiece: Identifiable {
    
    let id = UUID()
    var x: CGFloat
    var color: Color
    var size: CGFloat
    var speed: Double
    var angle: Angle
    var drift: CGFloat
    var isAnimate: Bool
    var spinX: Double
    var spinY: Double
}

extension ConfettiRainPiece {
    
    private static let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .orange, .purple]
    
    init(screenWidth: CGFloat) {
        x = CGFloat.random(in: 0...screenWidth)
        color = Self.colors.randomElement() ?? .red
        size = CGFloat.random(in: 8...16)
        speed = Double.random(in: 4...8)
        angle = .degrees(Double.random(in: 0...360))
        drift = CGFloat.random(in: -40...40)
        isAnimate = false
        spinX = Double.random(in: -60...60)
        spinY = Double.random(in: -60...60)
    }
}
