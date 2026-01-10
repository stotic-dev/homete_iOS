#!/bin/bash

set -e

RUBY_VERSION="3.3.10"

echo "rbenvをチェック中..."
if ! command -v rbenv &> /dev/null; then
    echo "rbenvをインストール中..."
    brew install rbenv ruby-build

    # シェル設定ファイルにrbenvの設定を追加（まだ追加されていない場合）
    if ! grep -q 'rbenv init' ~/.zprofile; then
        echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zprofile
        echo 'eval "$(rbenv init - zsh)"' >> ~/.zprofile
        echo "rbenv設定を~/.zprofileに追加しました"
    fi

    echo ""
    echo "⚠️  重要: 新しいターミナルセッションを開くか、以下を実行してください:"
    echo "    source ~/.zprofile"
    echo ""
fi

# rbenvを初期化
eval "$(rbenv init - zsh)"

echo "Ruby ${RUBY_VERSION}をチェック中..."
if ! rbenv versions | grep -q "$RUBY_VERSION"; then
    echo "Ruby ${RUBY_VERSION}をインストール中..."
    rbenv install "$RUBY_VERSION"
else
    echo "Ruby ${RUBY_VERSION}は既にインストールされています"
fi

echo "プロジェクトのRubyバージョンを${RUBY_VERSION}に設定中..."
rbenv local "$RUBY_VERSION"

# rbenv rehashを実行してshimsを更新
rbenv rehash

# 現在のシェルでもRubyバージョンを切り替え
export RBENV_VERSION="$RUBY_VERSION"

# 使用中のRubyバージョンを確認
echo "現在のRubyバージョン: $(rbenv exec ruby -v)"

echo "Bundlerをチェック中..."
if ! rbenv exec gem list bundler | grep -q "2.5.21"; then
    echo "Bundler 2.5.21をインストール中..."
    rbenv exec gem install bundler:2.5.21
    rbenv rehash
else
    echo "Bundler 2.5.21は既にインストールされています"
fi

echo "✅ Ruby環境のセットアップが完了しました"
