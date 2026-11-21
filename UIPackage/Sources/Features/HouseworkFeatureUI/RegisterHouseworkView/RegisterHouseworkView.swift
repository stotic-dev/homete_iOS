//
//  RegisterHouseworkView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import FrequentHouseworkFeatureUI
import HometeModel
import HometeResources
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

/// 家事の登録シートの中身
/// - Note: 「いつもの家事」から選ぶのと「新しく入力」するのを同じ登録予定リストにためて、まとめて登録する。
///         登録・シート・チュートリアルの進行は`RegisterHouseworkScreen`が受け持つ。
///         チュートリアルのスポットライトでナビゲーションバーまで覆うため、`NavigationStack`もここで持つ
public struct RegisterHouseworkView<Thumbnail: View, TutorialCard: View>: View {

    @Binding var draft: RegisterHouseworkDraft
    @Binding var selectedTab: RegisterSourceTab
    let frequentHouseworkContext: FrequentHouseworkContext
    /// いつもの家事の件数・画像の枚数の上限の判定に使う、操作している本人のプラン
    let isPremium: Bool
    /// 繰り返しを設定できるか
    let canSetRecurrence: Bool
    /// 「新しく入力」で以前に入力した家事
    let history: [HouseworkEntryHistoryItem]
    let isCameraAvailable: Bool
    /// 出しているチュートリアルのステップ
    let tutorialStep: RegisterHouseworkTutorialStep?
    let actions: Actions
    /// 添えた画像のサムネイル
    @ViewBuilder let thumbnail: (HouseworkImageUpload) -> Thumbnail
    /// チュートリアルのカード
    @ViewBuilder let tutorialCard: () -> TutorialCard

    public init(
        draft: Binding<RegisterHouseworkDraft>,
        selectedTab: Binding<RegisterSourceTab>,
        frequentHouseworkContext: FrequentHouseworkContext,
        isPremium: Bool,
        canSetRecurrence: Bool,
        history: [HouseworkEntryHistoryItem],
        isCameraAvailable: Bool,
        tutorialStep: RegisterHouseworkTutorialStep?,
        actions: Actions,
        @ViewBuilder thumbnail: @escaping (HouseworkImageUpload) -> Thumbnail,
        @ViewBuilder tutorialCard: @escaping () -> TutorialCard
    ) {
        _draft = draft
        _selectedTab = selectedTab
        self.frequentHouseworkContext = frequentHouseworkContext
        self.isPremium = isPremium
        self.canSetRecurrence = canSetRecurrence
        self.history = history
        self.isCameraAvailable = isCameraAvailable
        self.tutorialStep = tutorialStep
        self.actions = actions
        self.thumbnail = thumbnail
        self.tutorialCard = tutorialCard
    }

    public var body: some View {
        NavigationStack {
            RegisterSourceTabs(selectedTab: $selectedTab) {
                frequentTab()
            } manualContent: {
                manualTab()
            }
            .navigationTitle(.localized("家事を追加"))
            .inlineNavigationBarTitleDisplayMode()
            .leadingToolbarItem {
                NavigationBarButton(label: .close) {
                    actions.onTapCancel()
                }
            }
            #if os(iOS)
            .toolbar {
                trailingNavigationItems()
            }
            #endif
            // 2つのフローティングボタンは右下にまとめて縦に並べる。
            // `safeAreaInset`で場所を確保するとスクロール領域がその手前で切れ、
            // 中身がボタンの裏に回らず透けて見えなくなるため、`overlay`で浮かせる
            .overlay(alignment: .bottomTrailing) {
                VStack(alignment: .trailing, spacing: .space16) {
                    if selectedTab == .manual {
                        queueButton()
                    }
                    if !pendingEntries.isEmpty {
                        pendingEntriesButton()
                    }
                }
                .padding(.trailing, .space24)
                .padding(.bottom, .space24)
            }
            // 名前を1文字入れた時点で入力中の家事が登録予定に入るため、
            // ボタンの出現でフォームが跳ねないようにする
            .animation(.default, value: pendingEntries.isEmpty)
        }
        .tutorialSpotlight(
            isPresented: tutorialStep != nil,
            targets: tutorialStep.map(spotlightTargets) ?? []
        ) {
            tutorialCard()
        }
        .animation(.default, value: tutorialStep)
    }

}

public extension RegisterHouseworkView {

    /// 画面の操作
    struct Actions {

        let onTapCancel: () -> Void
        let onTapRegister: () -> Void
        let onTapQueue: () -> Void
        let onTapPendingEntries: () -> Void
        let onTapManageFrequent: () -> Void
        let onTapHistory: (HouseworkEntryHistoryItem) -> Void
        let onTapSaveAsFrequentWhenLimitReached: () -> Void
        let onTapMemo: () -> Void
        let onTapAddImage: (HouseworkImagePickSource) -> Void
        let onTapImagePremium: () -> Void
        let onTapImage: (HouseworkImageUpload.ID) -> Void

        public init(
            onTapCancel: @escaping () -> Void = {},
            onTapRegister: @escaping () -> Void = {},
            onTapQueue: @escaping () -> Void = {},
            onTapPendingEntries: @escaping () -> Void = {},
            onTapManageFrequent: @escaping () -> Void = {},
            onTapHistory: @escaping (HouseworkEntryHistoryItem) -> Void = { _ in },
            onTapSaveAsFrequentWhenLimitReached: @escaping () -> Void = {},
            onTapMemo: @escaping () -> Void = {},
            onTapAddImage: @escaping (HouseworkImagePickSource) -> Void = { _ in },
            onTapImagePremium: @escaping () -> Void = {},
            onTapImage: @escaping (HouseworkImageUpload.ID) -> Void = { _ in }
        ) {
            self.onTapCancel = onTapCancel
            self.onTapRegister = onTapRegister
            self.onTapQueue = onTapQueue
            self.onTapPendingEntries = onTapPendingEntries
            self.onTapManageFrequent = onTapManageFrequent
            self.onTapHistory = onTapHistory
            self.onTapSaveAsFrequentWhenLimitReached = onTapSaveAsFrequentWhenLimitReached
            self.onTapMemo = onTapMemo
            self.onTapAddImage = onTapAddImage
            self.onTapImagePremium = onTapImagePremium
            self.onTapImage = onTapImage
        }

    }

}

// MARK: - 表示内容

private extension RegisterHouseworkView {

    var limitPolicy: FrequentHouseworkLimitPolicy {
        .init(isPremium: isPremium)
    }

    var imagePolicy: HouseworkImagePolicy {
        .init(isPremium: isPremium)
    }

    /// くり返す家事はテンプレートに登録するため、画像を添えられない。選んだ画像は入力に残したまま隠し、
    /// くり返しをやめたらまた出す（登録予定リストには載せない）
    var canAddImages: Bool {
        draft.input.canAttachImages
    }

    var imageAddState: HouseworkImageAddState {
        .make(canAdd: canAddImages, policy: imagePolicy, currentCount: draft.input.images.count)
    }

    var pendingEntries: [PendingEntry] {
        draft.pendingEntries(context: frequentHouseworkContext)
    }

    var saveAsFrequentState: RegisterHouseworkDraft.SaveAsFrequentState {
        draft.saveAsFrequentState(context: frequentHouseworkContext, limitPolicy: limitPolicy)
    }

    func frequentTab() -> some View {
        FrequentHouseworkPicker(
            filterCategories: frequentHouseworkContext.sections.map(\.category),
            sections: frequentHouseworkContext.sections,
            selectedIds: Set(draft.selectedFrequentItemIds),
            disabledIds: limitPolicy.unusableItemIds(in: frequentHouseworkContext),
            onTapItem: { item in draft.toggleFrequentItem(item.id) },
            onTapManage: actions.onTapManageFrequent
        )
    }

    // ナビゲーションバー右側のボタン
    // - Note: 1つの`ToolbarItem`にまとめるとiOS26でガラスの背景がひとつながりになり、登録ボタンに付けた
    //         ブランドカラーが効かずシステム標準の色で塗られる。`ToolbarSpacer`で項目を分けて出す
    #if os(iOS)
    @ToolbarContentBuilder
    func trailingNavigationItems() -> some ToolbarContent {
        if selectedTab == .frequent {
            ToolbarItem(placement: .topBarTrailing) {
                manageFrequentButton()
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            registerButton()
        }
    }
    #endif

    func registerButton() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "paperplane.fill") {
            actions.onTapRegister()
        }
        // 繰り返しの入力が途中のときは、入力中の家事を含めて登録できない
        .disabled(pendingEntries.isEmpty || !draft.input.recurrenceInput.isValid)
        .accessibilityLabel(.localized("\(pendingEntries.count)件登録する"))
    }

    /// - Note: いつもの家事を選ぶときにしか使わないため、「いつもの家事」タブのときだけ出す
    func manageFrequentButton() -> some View {
        Button {
            actions.onTapManageFrequent()
        } label: {
            Image(systemName: "list.bullet")
        }
        .foregroundStyle(.textPrimary)
        .accessibilityLabel(.localized("いつもの家事を管理"))
    }

    /// 「続けて入力する」ボタン
    /// - Note: 入力欄の並びの中に置くと「これを押さないと登録できない」と読めてしまうため、
    ///         スクロールに載せず宙に浮かせて、あくまで追加の操作であることを示す
    func queueButton() -> some View {
        Button {
            actions.onTapQueue()
        } label: {
            HStack(spacing: .space4) {
                Image(systemName: "plus")
                Text("続けて入力する", bundle: #bundle)
            }
            .font(with: .headLineS)
        }
        .floatingButtonStyle()
        .disabled(!draft.canQueueCurrentInput)
        .tutorialSpotlightTarget(.registerHouseworkQueueButton)
    }

    func pendingEntriesButton() -> some View {
        PendingEntriesButton(count: pendingEntries.count) {
            actions.onTapPendingEntries()
        }
    }

    func manualTab() -> some View {
        ManualHouseworkForm(
            entry: $draft.input,
            categories: frequentHouseworkContext.categories,
            saveAsFrequentState: saveAsFrequentState,
            canSetRecurrence: canSetRecurrence,
            history: history,
            onTapHistory: actions.onTapHistory,
            onTapSaveAsFrequentWhenLimitReached: actions.onTapSaveAsFrequentWhenLimitReached,
            onTapMemo: actions.onTapMemo,
            images: canAddImages ? draft.input.images : [],
            imageAddState: imageAddState,
            imageNote: canAddImages ? nil : .localized("くり返す家事には、画像を添えられません"),
            isCameraAvailable: isCameraAvailable,
            onTapAddImage: actions.onTapAddImage,
            onTapImagePremium: actions.onTapImagePremium,
            onTapImage: actions.onTapImage,
            thumbnail: thumbnail
        )
    }

    func spotlightTargets(_ step: RegisterHouseworkTutorialStep) -> [TutorialSpotlightID] {
        switch step {
        case .inputSource:
            [.registerSourcePicker]

        case .queue:
            [.registerHouseworkQueueButton]

        case .saveAsFrequent:
            [.registerHouseworkSaveAsFrequent]
        }
    }

}

#if DEBUG
/// Preview用のデータ
enum RegisterHouseworkPreviewData {

    /// Preview用の、登録済みのいつもの家事
    static var frequentHouseworkContext: FrequentHouseworkContext {
        .init(items: [
            .makeForPreview(id: "1", title: "風呂掃除", categoryId: "preset.cleaning"),
            .makeForPreview(id: "2", title: "換気扇", point: 30, categoryId: "preset.cleaning", sortOrder: 1),
            .makeForPreview(id: "3", title: "布団干し", point: 20, categoryId: "preset.laundry"),
        ])
    }

}

#Preview("RegisterHouseworkView_いつもの家事あり") {
    RegisterHouseworkView(
        draft: .constant(.init(selectedFrequentItemIds: ["1", "3"])),
        selectedTab: .constant(.frequent),
        frequentHouseworkContext: RegisterHouseworkPreviewData.frequentHouseworkContext,
        isPremium: false,
        canSetRecurrence: true,
        history: [],
        isCameraAvailable: false,
        tutorialStep: nil,
        actions: .init(),
        thumbnail: { _ in EmptyView() },
        tutorialCard: { EmptyView() }
    )
    #if canImport(Prefire)
    .snapshot(perceptualPrecision: 0.95)
    #endif
}

#Preview("RegisterHouseworkView_いつもの家事なし") {
    RegisterHouseworkView(
        draft: .constant(.init()),
        selectedTab: .constant(.manual),
        frequentHouseworkContext: .init(),
        isPremium: false,
        canSetRecurrence: true,
        history: [],
        isCameraAvailable: false,
        tutorialStep: nil,
        actions: .init(),
        thumbnail: { _ in EmptyView() },
        tutorialCard: { EmptyView() }
    )
    #if canImport(Prefire)
    .snapshot(perceptualPrecision: 0.95)
    #endif
}

// - Note: 「続けて入力する」と「登録予定」の2つのフローティングボタンが重ならないかを見るためのPreview
#Preview("RegisterHouseworkView_新しく入力_登録予定あり") {
    RegisterHouseworkView(
        draft: .constant(.init(queuedEntries: [
            .init(
                id: "1",
                title: "ゴミ出し",
                point: 10,
                categoryId: nil,
                savesAsFrequent: false,
                recurrenceInput: .init(kind: .none)
            ),
        ])),
        selectedTab: .constant(.manual),
        frequentHouseworkContext: .init(),
        isPremium: false,
        canSetRecurrence: true,
        history: [],
        isCameraAvailable: false,
        tutorialStep: nil,
        actions: .init(),
        thumbnail: { _ in EmptyView() },
        tutorialCard: { EmptyView() }
    )
    #if canImport(Prefire)
    .snapshot(perceptualPrecision: 0.95)
    #endif
}

// - Note: チュートリアルのスポットライトは、切り抜くUIが位置を伝えてから描き直されるため、少し待ってから撮る
#Preview("RegisterHouseworkView_チュートリアル_入力方法") {
    RegisterHouseworkView(
        draft: .constant(.init()),
        selectedTab: .constant(.frequent),
        frequentHouseworkContext: RegisterHouseworkPreviewData.frequentHouseworkContext,
        isPremium: false,
        canSetRecurrence: true,
        history: [],
        isCameraAvailable: false,
        tutorialStep: .inputSource,
        actions: .init(),
        thumbnail: { _ in EmptyView() },
        tutorialCard: { RegisterHouseworkTutorialCard(step: .inputSource, onTapNext: {}, onTapBack: {}, onTapClose: {})
        }
    )
    #if canImport(Prefire)
    .snapshot(delay: 0.5, perceptualPrecision: 0.95)
    #endif
}

#Preview("RegisterHouseworkView_チュートリアル_まとめて登録") {
    RegisterHouseworkView(
        draft: .constant(.init()),
        selectedTab: .constant(.manual),
        frequentHouseworkContext: .init(),
        isPremium: false,
        canSetRecurrence: true,
        history: [],
        isCameraAvailable: false,
        tutorialStep: .queue,
        actions: .init(),
        thumbnail: { _ in EmptyView() },
        tutorialCard: { RegisterHouseworkTutorialCard(step: .queue, onTapNext: {}, onTapBack: {}, onTapClose: {}) }
    )
    #if canImport(Prefire)
    .snapshot(delay: 0.5, perceptualPrecision: 0.95)
    #endif
}

#Preview("RegisterHouseworkView_チュートリアル_上限でまとめて登録") {
    RegisterHouseworkView(
        draft: .constant(.init()),
        selectedTab: .constant(.manual),
        frequentHouseworkContext: .init(),
        isPremium: false,
        canSetRecurrence: true,
        history: [],
        isCameraAvailable: false,
        tutorialStep: .queue,
        actions: .init(),
        thumbnail: { _ in EmptyView() },
        tutorialCard: { RegisterHouseworkTutorialCard(
            step: .queue,
            steps: [.inputSource, .queue],
            onTapNext: {},
            onTapBack: {},
            onTapClose: {}
        ) }
    )
    #if canImport(Prefire)
    .snapshot(delay: 0.5, perceptualPrecision: 0.95)
    #endif
}

#Preview("RegisterHouseworkView_チュートリアル_いつもの家事に保存") {
    RegisterHouseworkView(
        draft: .constant(.init()),
        selectedTab: .constant(.manual),
        frequentHouseworkContext: .init(),
        isPremium: false,
        canSetRecurrence: true,
        history: [],
        isCameraAvailable: false,
        tutorialStep: .saveAsFrequent,
        actions: .init(),
        thumbnail: { _ in EmptyView() },
        tutorialCard: { RegisterHouseworkTutorialCard(
            step: .saveAsFrequent,
            onTapNext: {},
            onTapBack: {},
            onTapClose: {}
        ) }
    )
    #if canImport(Prefire)
    .snapshot(delay: 0.5, perceptualPrecision: 0.95)
    #endif
}
#endif
