.PHONY: help lint deploy emulator test-e2e resolve-packages build-local-package build-infra-package test-packages test-packages-fast affected build-affected test-affected snapshot-affected check-previews check-translations setup-project install-hooks format copy-xcode-cloud-secret

.DEFAULT_GOAL := setup-project

help: ## ヘルプを表示
	@grep -E '^[a-zA-Z0-9_-]+:.*## .*' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## ESLintを実行して自動修正
	cd firebase/functions && npm run lint -- --fix && cd ../..

deploy: ## FunctionsをSTGへデプロイ（本番はGitHub ActionsのDeploy Functionsをenvironment=prodで手動実行）
	cd firebase/functions && npm run deploy && cd ../..

emulator: ## エミュレーターを起動
	cd firebase/functions && npm run serve && cd ../..

test-e2e: ## E2Eテストを実行
	cd firebase/functions && npm run test:e2e && cd ../..

resolve-packages: ## SwiftPM依存を取得（Claude Codeのサンドボックスでは.git/configに書けないため、サンドボックス外で流す）
	scripts/resolve-swift-packages.sh

build-local-package: ## LocalPackageをiOSシミュレーター向けにビルド（自worktree内の多重実行はロックで直列化、他worktreeには影響しない）
	scripts/with-local-package-lock.sh $(CURDIR)/LocalPackage -- \
		swift build --package-path $(CURDIR)/LocalPackage --disable-sandbox --sdk $(shell xcrun --sdk iphonesimulator --show-sdk-path) --triple arm64-apple-ios26.2-simulator

build-infra-package: ## InfraPackage（HometeInfrastructure・AppRoot）をiOSシミュレーター向けにビルド。HometeDomainのプロトコルを変えたときの実装側の追従漏れはここで分かる
	scripts/with-local-package-lock.sh $(CURDIR)/InfraPackage -- \
		swift build --package-path $(CURDIR)/InfraPackage --disable-sandbox --sdk $(shell xcrun --sdk iphonesimulator --show-sdk-path) --triple arm64-apple-ios26.2-simulator

test-packages: ## LocalPackageのテストを実行（自worktree内の多重実行はロックで直列化、他worktreeには影響しない）
	scripts/with-local-package-lock.sh $(CURDIR)/LocalPackage -- \
		swift test --package-path $(CURDIR)/LocalPackage --disable-sandbox --enable-code-coverage

test-packages-fast: ## カバレッジなしでLocalPackageのテストを実行。FILTER=<テストターゲット/Suite名>で絞り込める（例: make test-packages-fast FILTER=HouseworkFeatureTests）
	scripts/with-local-package-lock.sh $(CURDIR)/LocalPackage -- \
		swift test --package-path $(CURDIR)/LocalPackage --disable-sandbox $(if $(FILTER),--filter '$(FILTER)')

# 変更の起点。affected系のターゲットは、ここからの分岐点以降のコミットと未コミットの変更を見る
BASE ?= origin/main
SIM_SDK = --sdk $(shell xcrun --sdk iphonesimulator --show-sdk-path) --triple arm64-apple-ios26.2-simulator

affected: ## 変更に関係するモジュールと、必要なビルド・テスト・VRTを表示（BASE=<ref>、既定はorigin/main）
	@python3 scripts/affected-modules.py summary --base $(BASE)

build-affected: ## 変更に関係するLocalPackageのターゲットだけiOS向けにビルドし、必要ならInfraPackageもビルド（BASE=<ref>）
	@targets="$$(python3 scripts/affected-modules.py build-targets --base $(BASE))"; \
	if [ -z "$$targets" ]; then echo "iOS向けにビルドするLocalPackageのターゲットはありません。"; fi; \
	for target in $$targets; do \
		echo "=== $$target ==="; \
		scripts/with-local-package-lock.sh $(CURDIR)/LocalPackage -- \
			swift build --package-path $(CURDIR)/LocalPackage --disable-sandbox $(SIM_SDK) --target $$target || exit 1; \
	done; \
	if [ "$$(python3 scripts/affected-modules.py infra --base $(BASE))" = yes ]; then \
		$(MAKE) build-infra-package; \
	else \
		echo "InfraPackageのビルドは不要です。"; \
	fi

test-affected: ## 変更に関係するテストターゲットだけ実行（BASE=<ref>）。COVERAGE=1でカバレッジ付き（CI用）
	@filter="$$(python3 scripts/affected-modules.py test-filter --base $(BASE))"; \
	if [ -z "$$filter" ]; then echo "変更に関係するテストターゲットが無いので、テストは流しません。"; exit 0; fi; \
	echo "テスト対象: $$filter"; \
	scripts/with-local-package-lock.sh $(CURDIR)/LocalPackage -- \
		swift test --package-path $(CURDIR)/LocalPackage --disable-sandbox $(if $(COVERAGE),--enable-code-coverage) --filter "$$filter"

snapshot-affected: ## 直接変えたHometeUI・Featureのプレビューだけ、ローカルでVRTを流す（BASE=<ref>）。参照スナップショットは更新しない
	scripts/run-affected-snapshots.sh $(BASE)

check-previews: ## VRT(Prefire)のビルドが壊れる#Previewを静的に検出
	python3 scripts/check-prefire-previews.py

check-translations: ## String Catalogの英訳の抜けと、使われなくなった文言を検出
	python3 scripts/check-missing-translations.py

copy-xcode-cloud-secret: ## Xcode Cloudに貼るSECRET_XCCONFIGをクリップボードへコピー。ENV=devでSECRET_XCCONFIG_DEV（例: make copy-xcode-cloud-secret ENV=dev）
	scripts/copy-xcode-cloud-secret.sh $(or $(ENV),prod)

install-hooks: ## git hooks（pre-commitでSwiftFormat実行）を有効化
	git config core.hooksPath scripts/git-hooks
	@echo "✅ git hooksを scripts/git-hooks に設定しました"

format: ## プロダクション+テストコード全体にSwiftFormatを実行
	swift package --package-path ProjectTools --disable-sandbox plugin \
		--allow-writing-to-package-directory \
		--allow-writing-to-directory $(CURDIR) \
		swiftformat --config .swiftformat \
		homete hometeSnapshotTests LocalPackage InfraPackage

setup-project: ## iOSプロジェクトのセットアップ
	@bash scripts/setup_ruby.sh
	@echo "Bundler依存関係をインストール中..."
	rbenv exec bundle config set --local path 'vendor/bundle'
	rbenv exec bundle install
	@echo "ProjectToolsをビルド中..."
	swift build --package-path ProjectTools --scratch-path ProjectTools/.build
	@echo "開発用プロビジョニングプロファイルを取得中..."
	rbenv exec bundle exec fastlane install_dev_profile
	@echo "本番用プロビジョニングプロファイルを取得中..."
	rbenv exec bundle exec fastlane install_prod_profile
	@$(MAKE) install-hooks
	@echo "✅ セットアップ完了！"
