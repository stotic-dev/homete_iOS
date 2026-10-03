//
//  HouseworkMemoEditScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeResources
import SwiftUI

/// 家事メモの編集シート
///
/// 家事・テンプレート・いつもの家事の各画面から開く。保存は呼び出し側が行う。
public struct HouseworkMemoEditScreen: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.routeResolver) var router
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(SubscriptionStore.self) var subscriptionStore

    @State var draft: HouseworkMemoDraft
    @State var isShowPaywall = false

    let onSave: (HouseworkMemo) -> Void

    /// - Parameters:
    ///   - memo: 編集前のメモ。新しく書く場合は`nil`
    ///   - onSave: 保存ボタンで確定したメモを受け取る。シートは閉じてから呼ぶ
    public init(memo: HouseworkMemo?, onSave: @escaping (HouseworkMemo) -> Void) {
        _draft = State(initialValue: HouseworkMemoDraft(original: memo))
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            HouseworkMemoEditView(
                draft: $draft,
                limitPolicy: limitPolicy,
                onTapClose: { dismiss() },
                onTapSave: { tappedSaveButton() },
                onTapAddItem: { draft.addItem(id: UUID().uuidString) },
                onTapUpgrade: { showPaywall() }
            )
        }
        .presentationDetents([.large])
        .fullScreenCoverOnIOS(
            isPresented: $isShowPaywall,
            onDismiss: { dismissedPaywall() },
            content: { router.resolve(.paywall) }
        )
    }

}

// MARK: - 表示内容

private extension HouseworkMemoEditScreen {

    var limitPolicy: HouseworkMemoLimitPolicy {
        .init(isPremium: subscriptionStore.isPremium)
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkMemoEditScreen {

    func tappedSaveButton() {
        guard draft.canSave(limitPolicy) else { return }
        let memo = draft.memo
        dismiss()
        onSave(memo)
    }

    func showPaywall() {
        analyticsClient.log(.paywall(.shown(step: .houseworkMemoLimit)))
        isShowPaywall = true
    }

    func dismissedPaywall() {
        analyticsClient.log(.paywall(.closed(step: .houseworkMemoLimit, isPremium: subscriptionStore.isPremium)))
    }

}

/// 家事メモの編集画面の中身
struct HouseworkMemoEditView: View {

    @Binding var draft: HouseworkMemoDraft
    @FocusState var focusedField: Field?
    /// スクロール領域の高さ。中身が短くても、余白のタップで入力を終えられるよう画面いっぱいに広げるのに使う
    @State var viewportHeight: CGFloat = .zero

    let limitPolicy: HouseworkMemoLimitPolicy
    let onTapClose: () -> Void
    let onTapSave: () -> Void
    let onTapAddItem: () -> Void
    let onTapUpgrade: () -> Void

    enum Field: Hashable {

        case text
        case item(HouseworkMemoDraft.Item.ID)

    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space24) {
                textSection()
                checklistSection()
                limitSection()
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space24)
            .frame(maxWidth: .infinity, minHeight: viewportHeight, alignment: .top)
            // 入力欄やボタンの外側（余白）をタップしたら入力を終える
            .background {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { endEditing() }
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            viewportHeight = height
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("メモ")
        .inlineNavigationBarTitleDisplayMode()
        .leadingToolbarItem {
            NavigationBarButton(label: .close) {
                onTapClose()
            }
        }
        .trailingToolbarItem {
            NavigationBarPrimaryActionButton(systemImage: "checkmark") {
                onTapSave()
            }
            .foregroundStyle(.onPrimary1)
            .disabled(!draft.canSave(limitPolicy))
        }
        .onChange(of: draft.checklist.count) { oldCount, newCount in
            // 追加した項目にすぐ入力できるようにする
            guard newCount > oldCount, let addedItem = draft.checklist.last else { return }
            focusedField = .item(addedItem.id)
        }
        .trackScreenView(.houseworkMemoEdit)
    }

}

// MARK: - UI定義

private extension HouseworkMemoEditView {

    /// セクションの見出しと、中身をひとまとまりに見せるカード（家事の登録シートと揃える）
    /// - Note: 見出しの字下げは、カードの中の文字の位置に揃える
    func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(title)
                .font(with: .boldCaption)
                .foregroundStyle(.onSurfaceVariant)
                .padding(.horizontal, .space16)
            VStack(alignment: .leading, spacing: .space16) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .sectionCardStyle { endEditing() }
        }
    }

    func textSection() -> some View {
        section("テキスト") {
            TextField("買う物や手順などを書いておけます", text: $draft.text, axis: .vertical)
                .font(with: .body)
                .lineLimit(3 ... 10)
                .focused($focusedField, equals: .text)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    func checklistSection() -> some View {
        section("チェックリスト") {
            ForEach(draft.checklist) { item in
                checklistItemRow(item)
                Divider()
            }
            Button {
                onTapAddItem()
            } label: {
                Label("項目を追加", systemImage: "plus")
                    .font(with: .body)
            }
            .disabled(!draft.canAddItem)
        }
    }

    func checklistItemRow(_ item: HouseworkMemoDraft.Item) -> some View {
        HStack(spacing: .space8) {
            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(.onSurfaceVariant)
                .accessibilityHidden(true)
            TextField("項目を入力", text: titleBinding(of: item.id))
                .font(with: .body)
                .focused($focusedField, equals: .item(item.id))
                .submitLabel(.next)
                .onSubmit {
                    onTapAddItem()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                draft.removeItem(id: item.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.onSurfaceVariant)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(deleteAccessibilityLabel(item))
        }
    }

    func limitSection() -> some View {
        VStack(alignment: .trailing, spacing: .space8) {
            Text("\(draft.memo.characterCount) / \(limitPolicy.maxCharacterCount.formatted())文字")
                .font(with: .caption)
                .foregroundStyle(draft.isOverLimit(limitPolicy) ? .alert : .onSurfaceVariant)
                .monospacedDigit()
            if draft.isOverLimit(limitPolicy), limitPolicy == .free {
                upgradeGuide()
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    func upgradeGuide() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("無料プランでは、メモを\(HouseworkMemoLimitPolicy.freeMaxCharacterCount)文字まで書けます")
                .font(with: .boldCaption)
                .foregroundStyle(.onSurface)
            Text(
                "プレミアムプランなら、\(HouseworkMemoLimitPolicy.premiumMaxCharacterCount.formatted())文字まで書けます。"
            )
            .font(with: .caption)
            .foregroundStyle(.onSurfaceVariant)
            Button("プレミアムプランを見る") {
                onTapUpgrade()
            }
            .font(with: .boldCaption)
        }
        .padding(.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(radius: .radius8)
                .fill(.subSurface)
        }
    }

    /// 名前が空の項目は「「」を削除」と読まれないようにする
    func deleteAccessibilityLabel(_ item: HouseworkMemoDraft.Item) -> String {
        let title = item.title.trimmingCharacters(in: .whitespaces)
        return title.isEmpty ? "項目を削除" : "「\(title)」を削除"
    }

    func endEditing() {
        focusedField = nil
    }

    func titleBinding(of id: HouseworkMemoDraft.Item.ID) -> Binding<String> {
        Binding {
            draft.checklist.first { $0.id == id }?.title ?? ""
        } set: { newValue in
            draft.updateTitle(newValue, of: id)
        }
    }

}

#if DEBUG
#Preview("HouseworkMemoEditView_新規") {
    NavigationStack {
        HouseworkMemoEditView(
            draft: .constant(.init(original: nil)),
            limitPolicy: .free,
            onTapClose: {},
            onTapSave: {},
            onTapAddItem: {},
            onTapUpgrade: {}
        )
    }
}

#Preview("HouseworkMemoEditView_入力済み") {
    NavigationStack {
        HouseworkMemoEditView(
            draft: .constant(.init(original: .init(
                text: "駅前のスーパーで。卵は特売日に",
                checklist: [
                    .init(id: "1", title: "牛乳", isChecked: true),
                    .init(id: "2", title: "卵", isChecked: false),
                    .init(id: "3", title: "食パン", isChecked: false),
                ]
            ))),
            limitPolicy: .free,
            onTapClose: {},
            onTapSave: {},
            onTapAddItem: {},
            onTapUpgrade: {}
        )
    }
}

#Preview("HouseworkMemoEditView_無料プランで上限超過") {
    NavigationStack {
        HouseworkMemoEditView(
            draft: .constant(.init(original: .init(
                text: String(repeating: "買い物メモ", count: 41),
                checklist: []
            ))),
            limitPolicy: .free,
            onTapClose: {},
            onTapSave: {},
            onTapAddItem: {},
            onTapUpgrade: {}
        )
    }
}
#endif
