//
//  CrackerPhysics.swift
//  LocalPackage
//

import Foundation

/// クラッカーから飛び出した紙片の動きを表す物理モデル
///
/// 経過時間だけから位置と速度が決まる閉じた式にしてあるため、
/// 紙片ごとに状態を持って毎フレーム更新する必要がない。
/// これによって数百枚の紙片でも`Canvas`の描画だけで済ませられる。
enum CrackerPhysics {

    /// 射出速度が空気抵抗で失われる速さ
    ///
    /// 値を大きくするほど早く失速し、飛距離が短くなる。
    private static let dragRate: Double = 2.6

    /// 落下の終端速度（pt/秒）
    ///
    /// 紙片は軽いので、重力で加速し続けずすぐ一定速度の落下に落ち着く。
    private static let terminalSpeed: Double = 210

    /// 終端速度に達するまでの時定数（秒）
    private static let fallTimeConstant: Double = 0.28

    /// 射出方向への移動量（初速1あたり）
    /// - Parameter time: 破裂からの経過時間
    /// - Returns: 射出方向に進んだ距離
    static func launchDisplacement(at time: TimeInterval) -> Double {
        (1 - exp(-dragRate * time)) / dragRate
    }

    /// 残っている射出速度の割合
    /// - Parameter time: 破裂からの経過時間
    /// - Returns: 初速に対する割合（0〜1）
    static func launchSpeedRatio(at time: TimeInterval) -> Double {
        exp(-dragRate * time)
    }

    /// 落下した距離
    /// - Parameter time: 破裂からの経過時間
    /// - Returns: 真下に落ちた距離
    static func fallDistance(at time: TimeInterval) -> Double {
        terminalSpeed * (time - fallTimeConstant * (1 - exp(-time / fallTimeConstant)))
    }

    /// 落下速度（pt/秒）
    /// - Parameter time: 破裂からの経過時間
    /// - Returns: そのときの落下速度
    static func fallSpeed(at time: TimeInterval) -> Double {
        terminalSpeed * (1 - exp(-time / fallTimeConstant))
    }

}
