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
    static var alert: Color { .adaptive(light: .p3(0xC0, 0x48, 0x48), dark: .p3(0xB7, 0x5C, 0x5D)) }
    static var destructive: Color { .adaptive(light: .p3(0xC0, 0x48, 0x48), dark: .p3(0xB7, 0x5C, 0x5D)) }
    static var loadingBg: Color { Color(white: 1, opacity: 0.3) }

    static var onDestructive: Color { .adaptive(light: .srgb(0xF7, 0xFC, 0xF7), dark: .srgb(0xF7, 0xFC, 0xF7)) }
    static var onPrimary1: Color { .adaptive(light: .srgb(0x0D, 0x1C, 0x0D), dark: .srgb(0xF7, 0xFC, 0xF7)) }
    static var onPrimary2: Color { .adaptive(light: .srgb(0xF7, 0xFC, 0xF7), dark: .srgb(0xF7, 0xFC, 0xF7)) }
    static var onPrimary3: Color { .adaptive(light: .srgb(0x0D, 0x1C, 0x0D), dark: .srgb(0xF7, 0xFC, 0xF7)) }
    static var onSubSurface: Color { .adaptive(light: .srgb(0x0D, 0x1C, 0x0D), dark: .srgb(0xF7, 0xFC, 0xF7)) }
    static var onSurface: Color { .adaptive(light: .srgb(0x0D, 0x1C, 0x0D), dark: .srgb(0xF7, 0xFC, 0xF7)) }

    static var primary1: Color { .adaptive(light: .srgb(0x47, 0xEB, 0x7D), dark: .p3(0x2A, 0x51, 0x2F)) }
    static var primary2: Color { .adaptive(light: .srgb(0x4D, 0x99, 0x4D), dark: .p3(0x20, 0x32, 0x1C)) }
    static var primary3: Color { .adaptive(light: .srgb(0xE8, 0xF2, 0xE8), dark: .p3(0x63, 0x65, 0x62)) }
    static var subSurface: Color { .adaptive(light: .srgb(0xFE, 0xFF, 0xFF), dark: .p3(0x44, 0x44, 0x44)) }
    static var surface: Color { .adaptive(light: .srgb(0xF7, 0xFA, 0xF7), dark: .srgb(0x0D, 0x1C, 0x0D)) }
}

// MARK: - Private Helpers

private extension Color {
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

private extension UIColor {
    static func srgb(_ r: Int, _ g: Int, _ b: Int, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: alpha)
    }

    static func p3(_ r: Int, _ g: Int, _ b: Int, alpha: CGFloat = 1) -> UIColor {
        UIColor(displayP3Red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: alpha)
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
