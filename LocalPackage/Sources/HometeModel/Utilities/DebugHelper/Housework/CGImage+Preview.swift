//
//  CGImage+Preview.swift
//  LocalPackage
//

import CoreGraphics

#if DEBUG

public extension CGImage {

    /// Preview用の、写真の代わりに表示する画像（斜めに2色で塗り分ける）
    static func makeForPreview(width: Int, height: Int) -> CGImage {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { preconditionFailure("Preview用の画像を描けませんでした") }
        context.setFillColor(CGColor(red: 0.62, green: 0.80, blue: 0.70, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(red: 0.98, green: 0.85, blue: 0.62, alpha: 1))
        context.move(to: .zero)
        context.addLine(to: CGPoint(x: width, y: 0))
        context.addLine(to: CGPoint(x: 0, y: height))
        context.fillPath()
        guard let image = context.makeImage() else { preconditionFailure("Preview用の画像を描けませんでした") }
        return image
    }

}

#endif
