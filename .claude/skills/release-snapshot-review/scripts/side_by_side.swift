// 前バージョン（左）と現在（右）のスナップショットを赤い区切り線を挟んで横に並べたPNGを作り、
// 同じサイズなら差分ピクセル数と差分の外接矩形を標準出力へ出す。
//
//   swiftc -O side_by_side.swift -o side_by_side
//   ./side_by_side <expected.png> <actual.png> <output.png>
//
// 出力例: "diff px=1136 bbox x34-716 y770-796" / "size 750x85 -> 750x88" / "nodiff"
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func load(_ path: String) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        FileHandle.standardError.write(Data("cannot load \(path)\n".utf8))
        exit(1)
    }
    return image
}

func pixels(of image: CGImage) -> [UInt8] {
    var buffer = [UInt8](repeating: 0, count: image.width * image.height * 4)
    let context = CGContext(
        data: &buffer,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: image.width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return buffer
}

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    print("usage: side_by_side <expected.png> <actual.png> <output.png>")
    exit(1)
}

let expected = load(arguments[1])
let actual = load(arguments[2])

if expected.width == actual.width, expected.height == actual.height {
    let lhs = pixels(of: expected)
    let rhs = pixels(of: actual)
    var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1, count = 0
    for y in 0 ..< expected.height {
        for x in 0 ..< expected.width {
            let index = (y * expected.width + x) * 4
            let delta = (0 ..< 3).reduce(0) { $0 + abs(Int(lhs[index + $1]) - Int(rhs[index + $1])) }
            // アンチエイリアス程度の揺れは無視する
            guard delta > 30 else { continue }
            count += 1
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
        }
    }
    // ビットマップのバッファは先頭行が画像の上端なので、y はそのまま画像上の座標（左上原点）になる
    print(count == 0 ? "nodiff" : "diff px=\(count) bbox x\(minX)-\(maxX) y\(minY)-\(maxY)")
} else {
    print("size \(expected.width)x\(expected.height) -> \(actual.width)x\(actual.height)")
}

let gap = 20
let width = expected.width + gap + actual.width
let height = max(expected.height, actual.height)
let canvas = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
canvas.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
canvas.fill(CGRect(x: 0, y: 0, width: width, height: height))
// 上端を揃えて描く（高さが違うときは下側に赤が残る）
canvas.draw(expected, in: CGRect(x: 0, y: height - expected.height, width: expected.width, height: expected.height))
canvas.draw(
    actual,
    in: CGRect(x: expected.width + gap, y: height - actual.height, width: actual.width, height: actual.height)
)

let destination = CGImageDestinationCreateWithURL(
    URL(fileURLWithPath: arguments[3]) as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
)!
CGImageDestinationAddImage(destination, canvas.makeImage()!, nil)
CGImageDestinationFinalize(destination)
