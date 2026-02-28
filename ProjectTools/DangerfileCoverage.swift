import Danger
import DangerSwiftCoverage

let danger = Danger()

// SPMカバレッジを報告する
// --cwd .（リポジトリルート）で実行するため、
// spmCoverageFolder にLocalPackage相対パスを指定
// SPMCoverageParser は currentDirectoryPath + "/" + spmCoverageFolder でパス解決する
Coverage.spmCoverage(
    spmCoverageFolder: "../LocalPackage/.build/debug/codecov",
    minimumCoverage: .zero
)
