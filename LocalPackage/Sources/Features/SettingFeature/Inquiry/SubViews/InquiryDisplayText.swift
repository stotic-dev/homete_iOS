//
//  InquiryDisplayText.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

/// 問い合わせの値を画面に出すときの文言
///
/// 一覧・詳細・作成の各画面で同じ言葉を使うため、ここにまとめる。
enum InquiryDisplayText {

    /// 送信に失敗したときの文言をどの送信で出すか
    enum SubmitContext {

        /// 問い合わせの作成
        case creation
        /// 問い合わせへの追加のメッセージ
        case message

    }

    static func category(_ category: InquiryCategory) -> LocalizedStringResource {
        switch category {
        case .bug:
            .localized("不具合")

        case .feature:
            .localized("ご要望")

        case .usage:
            .localized("使い方")

        case .account:
            .localized("アカウント・お支払い")

        case .other:
            .localized("その他")
        }
    }

    static func status(_ status: InquiryStatus) -> LocalizedStringResource {
        switch status {
        case .open:
            .localized("受付済み")

        case .inProgress:
            .localized("対応中")

        case .resolved:
            .localized("対応済み")
        }
    }

    static func submitFailureMessage(_ failure: InquiryFailure, context: SubmitContext) -> LocalizedStringResource {
        switch failure {
        case .rateLimited:
            switch context {
            case .creation:
                .localized("お問い合わせは24時間に5件まで送れます。時間をおいて、もう一度お試しください。")

            case .message:
                .localized("メッセージは1時間に30件まで送れます。時間をおいて、もう一度お試しください。")
            }

        case .invalidInput:
            .localized("本文は2,000文字以内で入力してください。")

        case .notFound:
            .localized("このお問い合わせは見つかりませんでした。")

        case .domain(.noNetwork):
            .localized("通信状態をご確認のうえ、もう一度お試しください。入力した内容はそのまま残っています。")

        case .domain(.failAuth):
            .localized("認証に失敗しました。再度サインインをお試しください。")

        case .domain:
            .localized("時間をおいて、もう一度お試しください。入力した内容はそのまま残っています。")
        }
    }

}
