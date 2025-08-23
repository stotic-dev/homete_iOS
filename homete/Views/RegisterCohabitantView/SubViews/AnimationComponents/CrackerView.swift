//
//  CrackerView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/23.
//

import SwiftUI

struct Ribbon: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var angle: Angle
    var speed: CGFloat
    var opacity: CGFloat
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var angle: Angle
    var speed: CGFloat
    var isShow: Bool
}

struct CrackerView: View {
    
    @State var ribbons: [Ribbon] = []
    @State var confettis: [ConfettiPiece] = []
    @State var launched = false
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .orange, .purple]
    
    let completion: () -> Void
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 紙吹雪
                ForEach(confettis) { piece in
                    Rectangle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                        .position(x: piece.x, y: piece.y)
                        .opacity(piece.isShow ? 1 : 0)
                }
                // 紙テープ
                ForEach(ribbons) { ribbon in
                    Capsule()
                        .fill(ribbon.color)
                        .rotationEffect(ribbon.angle)
                        .frame(width: 6, height: 100)
                        .position(x: ribbon.x, y: ribbon.y)
                        .opacity(ribbon.opacity)
                }
                // クラッカー本体 (左下に配置)
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "party.popper.fill")
                            .resizable()
                            .symbolEffect(.bounce, value: launched)
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.orange, .yellow)
                            .rotationEffect(.degrees(-30)) // 右上に向ける
                            .onAppear {
                                fireCracker(screenHeight: proxy.size.height)
                            }
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

private extension CrackerView {
    
    func fireCracker(screenHeight: CGFloat) {
        ribbons.removeAll()
        confettis.removeAll()
        launched = false
        
        let startX: CGFloat = 60
        let startY: CGFloat = screenHeight - 120
        
        // 紙吹雪
        confettis = confettis.map {
            
            var piece = $0
            piece.isShow.toggle()
            return piece
        }
        
        for _ in 0..<100 {
            let confetti = ConfettiPiece(
                size: 8,
                x: startX,
                y: startY,
                color: colors.randomElement()!,
                angle: .degrees(Double.random(in: -50...50)),
                speed: 0.6,
                isShow: true
            )
            confettis.append(confetti)
        }
        
        // 紙テープ生成（右上方向へランダムに発射）
        for _ in 0..<25 {
            let ribbon = Ribbon(
                x: startX,
                y: startY,
                color: colors.randomElement()!,
                angle: .degrees(Double.random(in: -10...50)),
                speed: Double.random(in: 0.5...1),
                opacity: 1
            )
            ribbons.append(ribbon)
        }
        
        // アニメーション開始
        launched = true
        
        withAnimation(.default) {
            for i in 0..<confettis.count {
                // 右上方向に飛ばす
                let dx = CGFloat.random(in: (startX - 70)...(startX + 120))
                let dy = CGFloat.random(in: (startY - 150)...(startY + 30))
                
                confettis[i].x = dx
                confettis[i].y = dy
            }
        } completion: {
            withAnimation(.linear(duration: 1.5)) {
                for i in 0..<confettis.count {
                    confettis[i].y += 50
                    confettis[i].isShow = false
                }
            } completion: {
                completion()
            }
        }
        
        for i in 0..<ribbons.count {
            // 右上方向に飛ばす
            let degrees = ribbons[i].angle.degrees
            let dx = degrees * 10
            let dy = 0.0
            
            withAnimation(.easeInOut(duration: ribbons[i].speed)) {
                ribbons[i].x = dx
                ribbons[i].y = dy
            }
            
            Task {
                
                try await Task.sleep(for: .seconds(ribbons[i].speed / CGFloat(2)))
                withAnimation {
                    ribbons[i].opacity = 0
                }
            }
        }
    }
}

#Preview {
    CrackerView {
        print("finish")
    }
}
