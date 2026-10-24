//
//  WelcomePage.swift
//  LocalPackage
//

/// ログイン前の説明画面で、順に見せるページ
enum WelcomePage: Hashable, CaseIterable {

    /// 家事を記録する
    case record
    /// パートナーと共有する
    case share
    /// ありがとうを送り合う
    case thanks

    /// 次のページ。最後のページならnil
    var next: WelcomePage? {
        let pages = Self.allCases
        guard let index = pages.firstIndex(of: self), index + 1 < pages.count else { return nil }
        return pages[index + 1]
    }

}
