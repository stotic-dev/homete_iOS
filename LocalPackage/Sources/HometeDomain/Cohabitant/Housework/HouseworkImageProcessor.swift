//
//  HouseworkImageProcessor.swift
//  LocalPackage
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// 家事に添える画像の縮小・圧縮と、表示用の読み込み
///
/// 保存費用と通信量を抑えるため、上げる前に端末で長辺1,600px・JPEGに縮小する。
/// 撮影した写真の位置情報が同居人以外に渡らないよう、Exif・GPSなどのメタデータは書き出さない（ADR-0067）。
public enum HouseworkImageProcessor {

    /// 上げる画像の長辺の最大ピクセル数
    public static let maxPixelSize = 1600
    /// 上げる画像の最大バイト数。Storageのルールでも同じ上限を検査する
    public static let maxByteCount = 2 * 1024 * 1024
    /// 試すJPEGの画質。最大バイト数に収まるまで順に下げる
    static let compressionQualities: [Double] = [0.8, 0.6, 0.4, 0.2]

    /// 上げる画像を作る
    ///
    /// 長辺が`maxPixelSize`を超える画像は縮小し、向き（Exifの回転情報）は画素に焼き込んでから捨てる。
    /// JPEGは透過を持てないため、透過した部分は白で塗る（そのままだと黒くなる）。
    /// - Parameter data: フォトライブラリ・カメラから受け取った画像（HEIC・JPEG・PNGなど）
    /// - Returns: メタデータを持たないJPEG
    /// - Throws: 画像として読めない、または最低画質でも上限に収まらない場合は`HouseworkImageError.unreadable`
    public static func makeUploadData(from data: Data) throws -> Data {
        guard let image = makeImage(from: data, maxPixelSize: maxPixelSize).flatMap(flattenedOnWhite) else {
            throw HouseworkImageError.unreadable
        }
        for quality in compressionQualities {
            if let jpeg = makeJPEG(image, quality: quality), jpeg.count <= maxByteCount {
                return jpeg
            }
        }
        throw HouseworkImageError.unreadable
    }

    /// 画像を、長辺が`maxPixelSize`以下になるよう縮小して読み込む（メインスレッドの外で行う）
    @concurrent
    public static func loadImage(from data: Data, maxPixelSize: Int) async -> CGImage? {
        makeImage(from: data, maxPixelSize: maxPixelSize)
    }

    /// 画像を、長辺が`maxPixelSize`以下になるよう縮小して読み込む
    ///
    /// 一覧のサムネイルで元の大きさのまま展開するとメモリを大きく使うため、表示する大きさに合わせて読み込む。
    /// 元の画像のほうが小さいときは拡大しない。
    /// - Returns: 画像として読めない場合は`nil`
    public static func makeImage(from data: Data, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

}

private extension HouseworkImageProcessor {

    /// 白い背景に描いた、透過を持たない画像にする
    static func flattenedOnWhite(_ image: CGImage) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }
        let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(rect)
        context.draw(image, in: rect)
        return context.makeImage()
    }

    /// 画素だけをJPEGに書き出す。プロパティを渡さないため、元の画像のメタデータは引き継がれない
    static func makeJPEG(_ image: CGImage, quality: Double) -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }

}
