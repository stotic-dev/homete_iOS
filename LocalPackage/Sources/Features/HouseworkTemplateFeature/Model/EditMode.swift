//
//  EditMode.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/16.
//

enum EditMode {

    /// テンプレートの家事新規作成
    case create
    /// テンプレートの家事編集
    case edit(before: TemplateItemEditInput)

}
