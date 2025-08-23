//
//  ConfettiRainView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/23.
//

import Combine
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

struct ConfettiRainView: View {
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .orange, .purple]
    
    @State private var confettis: [ConfettiRainPiece] = []
    @State var timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { proxy in
            ForEach(confettis) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 1.5)
                    .position(x: piece.x, y: -20)
                    .rotationEffect(piece.angle)
                    .rotation3DEffect(
                        .degrees(piece.isAnimate ? 90 : 0),
                        axis: (x: piece.spinX, y: piece.spinY, z: 0)
                    )
                    .offset(y: piece.isAnimate ? proxy.size.height + 50 : 0)
                    .offset(x: piece.isAnimate ? piece.drift : 0)
            }
            .onReceive(timer) { _ in
                spawnConfetti(screenSize: proxy.size)
            }
        }
        .drawingGroup()
    }
}

private extension ConfettiRainView {
    
    func spawnConfetti(screenSize: CGSize) {
        
        for _ in 0..<10 {
            
            let piece = ConfettiRainPiece(
                x: CGFloat.random(in: 0...screenSize.width),
                color: colors.randomElement() ?? .red,
                size: CGFloat.random(in: 8...16),
                speed: Double.random(in: 4...8),
                angle: .degrees(Double.random(in: 0...360)),
                drift: CGFloat.random(in: -40...40),
                isAnimate: false,
                spinX: Double.random(in: -60...60),
                spinY: Double.random(in: -60...60)
            )
            confettis.append(piece)
            
            // 画面下まで落ちたら削除
            withAnimation(.linear(duration: piece.speed)) {
                
                guard let index = confettis.firstIndex(where: { $0.id == piece.id }) else { return }
                confettis[index].isAnimate = true
            } completion: {
                
                guard let index = confettis.firstIndex(where: { $0.id == piece.id }) else { return }
                confettis.remove(at: index)
            }
        }
    }
}

#Preview("ConfettiRain") {
    ConfettiRainView()
        .ignoresSafeArea()
}
