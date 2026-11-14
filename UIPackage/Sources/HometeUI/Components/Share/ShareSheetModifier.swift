//
//  ShareSheetModifier.swift
//  LocalPackage
//

import SwiftUI

public extension View {

    /// `item`が入ったら共有シートを出し、シートが閉じきって共有の結果が分かった時点で`onFinish`を呼ぶ
    ///
    /// `UIActivityViewController`の完了ハンドラは、シートが閉じた**後**に呼ばれることがある。
    /// `.sheet`の`onDismiss`で完了ハンドラの結果を見ると、共有を終えていても未完了と判断してしまうため、
    /// どちらが先に来ても、両方そろった時点で1回だけ伝える。
    /// 共有の後に次の画面やシートを出す処理は、シートが閉じた後に動くよう`onFinish`の中で行う。
    /// - Parameters:
    ///   - item: 共有するもの。閉じると`nil`に戻る
    ///   - text: 共有するテキスト
    ///   - url: 共有するURL。`nil`ならシートの中に何も出さない
    ///   - onFinish: 共有シートが閉じきったときに呼ばれる。共有先のアプリで共有まで完了した場合は`isCompleted`が`true`
    func shareSheet<Item: Identifiable>(
        item: Binding<Item?>,
        text: String,
        url: @escaping (Item) -> URL?,
        onFinish: @escaping (_ item: Item, _ isCompleted: Bool) -> Void
    ) -> some View {
        modifier(ShareSheetModifier(item: item, text: text, url: url, onFinish: onFinish))
    }

}

private struct ShareSheetModifier<Item: Identifiable>: ViewModifier {

    @Binding var item: Item?
    let text: String
    let url: (Item) -> URL?
    let onFinish: (Item, Bool) -> Void

    /// 完了ハンドラで受け取った結果。シートが閉じるまで持っておく
    @State var result: (item: Item, isCompleted: Bool)?
    @State var isDismissed = false

    func body(content: Content) -> some View {
        content
            .sheet(
                item: $item,
                onDismiss: {
                    isDismissed = true
                    finishIfReady()
                },
                content: { sharingItem in
                    if let url = url(sharingItem) {
                        ShareSheet(text: text, url: url) { isCompleted in
                            result = (sharingItem, isCompleted)
                            finishIfReady()
                        }
                    }
                }
            )
            // 前の共有で完了ハンドラが呼ばれなかったときに、閉じた印が次の共有へ持ち越されないようにする
            .onChange(of: item == nil) {
                guard item != nil else { return }
                result = nil
                isDismissed = false
            }
    }

    func finishIfReady() {
        guard isDismissed, let result else { return }
        self.result = nil
        isDismissed = false
        onFinish(result.item, result.isCompleted)
    }

}
