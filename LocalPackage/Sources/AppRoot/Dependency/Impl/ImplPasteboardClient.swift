//
//  ImplPasteboardClient.swift
//

#if os(iOS)
import Foundation
import HometeDomain
import UIKit

public extension PasteboardClient {

    static let liveValue: PasteboardClient = .init(
        detectProbableWebURL: { await detectProbableWebURL() },
        readURL: { await readURL() }
    )

}

private extension PasteboardClient {

    /// `detectPatterns`は内容を読まないためペースト通知は出ない。ここで分かるのは「URLらしきものがある」ことだけ
    @MainActor
    static func detectProbableWebURL() async -> PasteboardDetection {
        let pasteboard = UIPasteboard.general
        let changeCount = pasteboard.changeCount

        // detectPatternsにはasync版が無いため、completionHandler版を包む
        // 検出結果（KeyPathの集合）はSendableでないため、continuationに渡す前にBoolへ畳む
        let hasProbableWebURL = await withCheckedContinuation { continuation in
            pasteboard.detectPatterns(for: [\.probableWebURL]) { result in
                switch result {
                case let .success(patterns):
                    continuation.resume(returning: patterns.contains(\.probableWebURL))

                case .failure:
                    // 検出に失敗した場合（クリップボードが空など）は案内を出さない
                    continuation.resume(returning: false)
                }
            }
        }
        return .init(hasProbableWebURL: hasProbableWebURL, changeCount: changeCount)
    }

    /// 内容を読み取るためシステムのペースト通知が出る。ユーザー操作起点でのみ呼ばれる前提
    @MainActor
    static func readURL() -> URL? {
        let pasteboard = UIPasteboard.general
        if let url = pasteboard.url {
            return url
        }
        // 着地ページはテキストとしてコピーするため、文字列からもURLを組み立てる
        guard let string = pasteboard.string?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        return URL(string: string)
    }

}
#endif
