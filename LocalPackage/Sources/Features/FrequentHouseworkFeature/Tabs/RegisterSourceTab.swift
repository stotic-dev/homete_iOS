//
//  RegisterSourceTab.swift
//  LocalPackage
//

/// 家事を追加するときの入力方法
public enum RegisterSourceTab: String, CaseIterable, Identifiable, Sendable {

    /// 登録済みのいつもの家事から選ぶ
    case frequent
    /// 名前とポイントを新しく入力する
    case manual

    public var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .frequent:
            "いつもの家事"

        case .manual:
            "新しく入力"
        }
    }

    /// 最初に開くタブ
    /// - Note: いつもの家事が1件もないときに「いつもの家事」を開くと空の画面から始まるため、「新しく入力」を開く
    public static func initial(hasFrequentHousework: Bool) -> Self {
        hasFrequentHousework ? .frequent : .manual
    }

}
