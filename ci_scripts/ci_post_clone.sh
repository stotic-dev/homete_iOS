#!/bin/sh

# Xcode CloudでSwift Package Managerプラグインの検証をスキップする
# PrefireTestsPluginなどのパッケージプラグインを許可するために必要
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
