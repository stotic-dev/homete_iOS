//
//  HouseworkImageProcessorTest.swift
//  LocalPackage
//

import CoreGraphics
import Foundation
@testable import HometeDomain
import ImageIO
import Testing
import UniformTypeIdentifiers

struct HouseworkImageProcessorTest {

    /// 書き出した画像のうち、検証したい性質
    struct ImageSummary: Equatable {

        let typeIdentifier: String
        let width: Int
        let height: Int
        let hasGPS: Bool
        let hasExif: Bool

    }

    @Test(
        "上げる画像は、長辺1,600pxまでに縮小したJPEGになり、位置情報などのメタデータを持たない",
        arguments: [
            (3200, 2400, 1600, 1200),
            (1200, 4000, 480, 1600),
            (800, 600, 800, 600),
        ]
    )
    func makeUploadData_resizesAndStripsMetadata(
        width: Int,
        height: Int,
        expectedWidth: Int,
        expectedHeight: Int
    ) throws {
        // Arrange

        let source = try Self.makePNGWithMetadata(width: width, height: height)

        // Act

        let actual = try HouseworkImageProcessor.makeUploadData(from: source)

        // Assert

        let expected = ImageSummary(
            typeIdentifier: UTType.jpeg.identifier,
            width: expectedWidth,
            height: expectedHeight,
            hasGPS: false,
            hasExif: false
        )
        #expect(try Self.summary(of: actual) == expected)
    }

    @Test("Exifの向きが90度回転の写真は、向きを画素に焼き込み、縦横を入れ替えた画像になる")
    func makeUploadData_rotatedPhoto_appliesOrientation() throws {
        // Arrange

        let source = try Self.makeJPEG(width: 400, height: 200, orientation: 6)

        // Act

        let actual = try HouseworkImageProcessor.makeUploadData(from: source)

        // Assert

        let expected = ImageSummary(
            typeIdentifier: UTType.jpeg.identifier,
            width: 200,
            height: 400,
            hasGPS: false,
            hasExif: false
        )
        #expect(try Self.summary(of: actual) == expected)
    }

    @Test("画像として読めないデータは、unreadableのエラーになる")
    func makeUploadData_invalidData_throwsUnreadable() {
        // Act & Assert

        #expect(throws: HouseworkImageError.unreadable) {
            try HouseworkImageProcessor.makeUploadData(from: Data("not an image".utf8))
        }
    }

    @Test("表示用に読み込むと、長辺が指定したピクセル数までに縮小される")
    func makeImage_resizesToMaxPixelSize() throws {
        // Arrange

        let source = try Self.makePNGWithMetadata(width: 1000, height: 500)

        // Act

        let actual = HouseworkImageProcessor.makeImage(from: source, maxPixelSize: 200)

        // Assert

        #expect(actual.map { [$0.width, $0.height] } == [200, 100])
    }

}

private extension HouseworkImageProcessorTest {

    struct ImageCreationError: Error {}

    /// 位置情報とExifを持つPNGを作る
    static func makePNGWithMetadata(width: Int, height: Int) throws -> Data {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw ImageCreationError() }
        context.setFillColor(CGColor(red: 0.2, green: 0.6, blue: 0.4, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else { throw ImageCreationError() }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else { throw ImageCreationError() }
        let properties: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 35.68,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 139.76,
                kCGImagePropertyGPSLongitudeRef: "E",
            ],
            kCGImagePropertyExifDictionary: [
                kCGImagePropertyExifUserComment: "test",
            ],
        ]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ImageCreationError() }
        return output as Data
    }

    /// Exifの向き（1〜8）を持つJPEGを作る
    static func makeJPEG(width: Int, height: Int, orientation: Int) throws -> Data {
        let png = try makePNGWithMetadata(width: width, height: height)
        guard let source = CGImageSourceCreateWithData(png as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { throw ImageCreationError() }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { throw ImageCreationError() }
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ImageCreationError() }
        return output as Data
    }

    static func summary(of data: Data) throws -> ImageSummary {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let typeIdentifier = CGImageSourceGetType(source) as String?,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else { throw ImageCreationError() }
        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        return .init(
            typeIdentifier: typeIdentifier,
            width: width,
            height: height,
            hasGPS: properties[kCGImagePropertyGPSDictionary] != nil,
            hasExif: exif?[kCGImagePropertyExifUserComment] != nil
        )
    }

}
