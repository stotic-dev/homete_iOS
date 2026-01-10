.PHONY: help lint deploy emulator test-e2e setup-project

.DEFAULT_GOAL := setup-project

help: ## ヘルプを表示
	@grep -E '^[a-zA-Z0-9_-]+:.*## .*' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## ESLintを実行して自動修正
	cd firebase/functions && npm run lint -- --fix && cd ../..

deploy: ## Functionsをデプロイ
	cd firebase/functions && npm run deploy && cd ../..

emulator: ## エミュレーターを起動
	cd firebase/functions && npm run serve && cd ../..

test-e2e: ## E2Eテストを実行
	cd firebase/functions && npm run test:e2e && cd ../..

setup-project: ## iOSプロジェクトのセットアップ
	@echo "Bundler依存関係をインストール中..."
	bundle config set --local path 'vendor/bundle'
	bundle install
	@echo "ProjectToolsをビルド中..."
	swift build --package-path ProjectTools --scratch-path ProjectTools/.build
	@echo "開発用プロビジョニングプロファイルを取得中..."
	bundle exec fastlane install_dev_profile
	@echo "本番用プロビジョニングプロファイルを取得中..."
	bundle exec fastlane install_prod_profile
	@echo "セットアップ完了！"
