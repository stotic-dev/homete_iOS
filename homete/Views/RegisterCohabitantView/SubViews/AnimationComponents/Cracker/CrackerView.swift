//
//  CrackerView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/23.
//

import SwiftUI

struct CrackerView: View {
    
    @State var ribbons: [CrackerRibbon] = []
    @State var confettis: [CrackerConfettiPiece] = []
    @State var launched = false
    
    /// アニメーション終了したら呼ばれるクロージャ
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
                    .padding(.leading, DesignSystem.Space.space24)
                    .padding(.bottom, DesignSystem.Space.space40)
                }
            }
        }
    }
}

private extension CrackerView {
    
    func fireCracker(screenHeight: CGFloat) {
        
        launched = false
        
        let startX: CGFloat = 60
        let startY: CGFloat = screenHeight - 120
        
        confettis = CrackerConfettiPiece.makeConfettis(startX: startX, startY: startY)
        ribbons = CrackerRibbon.makeRibbons(startX: startX, startY: startY)
        
        // アニメーション開始
        launched = true
        
        withAnimation(.default) {
            
            for i in 0..<confettis.count {
                
                confettis[i] = confettis[i].explosion(startX: startX, startY: startY)
            }
        } completion: {
            
            withAnimation(.linear(duration: 1.5)) {
                
                for i in 0..<confettis.count {
                    
                    confettis[i] = confettis[i].scatter()
                }
            } completion: {
                
                confettis.removeAll()
                completion()
            }
        }
        
        for i in 0..<ribbons.count {
            
            withAnimation(.easeInOut(duration: ribbons[i].speed)) {
                
                ribbons[i] = ribbons[i].explosion()
            }
            
            Task {
                
                try await Task.sleep(for: .seconds(ribbons[i].speed / CGFloat(2)))
                withAnimation {
                    
                    ribbons[i] = ribbons[i].scatter()
                } completion: {
                    
                    ribbons.removeAll()
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
