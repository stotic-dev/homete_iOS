//
//  ScreenTutorial.swift
//  LocalPackage
//

/// 初めて開いたときに、使い方を説明するチュートリアルを出す画面
/// - Note: 画面ごとに一度だけ出す。「見た」の記録とAnalyticsのパラメータにrawValueを使う
public enum ScreenTutorial: String, CaseIterable, Sendable {

    /// 家事登録シート
    case registerHousework = "register_housework"
    /// 家事テンプレート画面
    case houseworkTemplate = "housework_template"

}

/// 画面を初めて開いたときに出すチュートリアルのステップ
public protocol ScreenTutorialStep: TutorialStep, RawRepresentable where RawValue == String {

    /// どの画面のチュートリアルか
    static var screen: ScreenTutorial { get }

}

/// 家事登録シートのチュートリアルのステップ
public enum RegisterHouseworkTutorialStep: String, ScreenTutorialStep {

    /// 「いつもの家事」と「新しく入力」の違い
    case inputSource = "input_source"
    /// 続けて入力して、まとめて登録できること
    case queue
    /// いつもの家事に保存すると、次から選べること
    case saveAsFrequent = "save_as_frequent"

    public static let screen = ScreenTutorial.registerHousework

}

/// 家事テンプレート画面のチュートリアルのステップ
/// - Note: テンプレートの有無に関係なく、作成から保存までの流れを順に説明する
public enum HouseworkTemplateTutorialStep: String, ScreenTutorialStep {

    /// テンプレートを作成する
    case create
    /// ＋から家事を追加する
    case addItem = "add_item"
    /// 登録した家事が、その曜日・その日の家事ボードに自動で並ぶ
    case autoPlacement = "auto_placement"
    /// ✓で保存すると、ボードに反映されてパートナーとも共有される
    case save

    public static let screen = ScreenTutorial.houseworkTemplate

}
