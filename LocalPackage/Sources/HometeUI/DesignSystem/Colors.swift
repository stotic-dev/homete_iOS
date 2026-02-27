//
//  Colors.swift
//  homete
//
//  Created by Daiki Fujimori on 2026/02/26.
//

#if canImport(UIKit)
import SwiftUI
import UIKit

// MARK: - Color Definitions

public extension ShapeStyle where Self == Color {
    static var alert: Color { .adaptive(light: .srgb(0xC04848), dark: .srgb(0xB75C5D)) }
    static var destructive: Color { .adaptive(light: .srgb(0xC04848), dark: .srgb(0xB75C5D)) }
    static var loadingBg: Color { Color(white: 1, opacity: 0.3) }

    static var onDestructive: Color { .adaptive(light: .srgb(0xF7FCF7), dark: .srgb(0xF7FCF7)) }
    static var onPrimary1: Color { .adaptive(light: .srgb(0x0D1C0D), dark: .srgb(0xF7FCF7)) }
    static var onPrimary2: Color { .adaptive(light: .srgb(0xF7FCF7), dark: .srgb(0xF7FCF7)) }
    static var onPrimary3: Color { .adaptive(light: .srgb(0x0D1C0D), dark: .srgb(0xF7FCF7)) }
    static var onSubSurface: Color { .adaptive(light: .srgb(0x0D1C0D), dark: .srgb(0xF7FCF7)) }
    static var onSurface: Color { .adaptive(light: .srgb(0x0D1C0D), dark: .srgb(0xF7FCF7)) }

    static var primary1: Color { .adaptive(light: .srgb(0x47EB7D), dark: .srgb(0x2A512F)) }
    static var primary2: Color { .adaptive(light: .srgb(0x4D994D), dark: .srgb(0x20321C)) }
    static var primary3: Color { .adaptive(light: .srgb(0xE8F2E8), dark: .srgb(0x636562)) }
    static var subSurface: Color { .adaptive(light: .srgb(0xFEFFFF), dark: .srgb(0x444444)) }
    static var surface: Color { .adaptive(light: .srgb(0xF7FAF7), dark: .srgb(0x0D1C0D)) }
}

// MARK: - Private Helpers

private extension Color {
    /// ライト/ダークモードで色を切り替える `Color` を返す。
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

private extension UIColor {
    /// sRGB色空間で `0xRRGGBB` 形式の16進数から `UIColor` を生成する。
    static func srgb(_ hex: Int, alpha: CGFloat = 1) -> UIColor {
        .init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Preview

#Preview("ColorPalette - Light", traits: .sizeThatFitsLayout) {
    ColorPaletteView()
        .preferredColorScheme(.light)
}

#Preview("ColorPalette - Dark", traits: .sizeThatFitsLayout) {
    ColorPaletteView()
        .preferredColorScheme(.dark)
}

private struct ColorPaletteView: View {
    private let palette: [(name: String, color: Color)] = [
        ("primary1", .primary1),
        ("primary2", .primary2),
        ("primary3", .primary3),
        ("surface", .surface),
        ("subSurface", .subSurface),
        ("onSurface", .onSurface),
        ("onSubSurface", .onSubSurface),
        ("onPrimary1", .onPrimary1),
        ("onPrimary2", .onPrimary2),
        ("onPrimary3", .onPrimary3),
        ("alert", .alert),
        ("destructive", .destructive),
        ("onDestructive", .onDestructive),
        ("loadingBg", .loadingBg),
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
            ForEach(palette, id: \.name) { item in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.color)
                        .frame(height: 56)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.onSurface.opacity(0.1), lineWidth: 1)
                        }
                    Text(item.name)
                        .font(.system(size: 11))
                        .foregroundStyle(.onSurface)
                }
            }
        }
        .padding(16)
        .background(.surface)
    }
}
#endif
