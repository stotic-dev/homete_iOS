import Foundation
import PackagePlugin

@main
struct SwiftLintPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let swiftlintExecutable = try context.tool(named: "swiftlint")

        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }

        let swiftFiles = sourceTarget.sourceFiles(withSuffix: "swift").map(\.url)
        guard !swiftFiles.isEmpty else {
            return []
        }

        // パッケージディレクトリから上に向かって .swiftlint.yml が存在するディレクトリを探す
        let workingDirectory = findConfigDirectory(startingFrom: context.package.directoryURL)

        let cacheURL = context.pluginWorkDirectoryURL.appending(path: "Cache")
        try FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        let outputURL = context.pluginWorkDirectoryURL.appending(path: "Output")
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let arguments: [String] = [
            "lint",
            "--quiet",
            "--force-exclude",
            "--cache-path", cacheURL.path(percentEncoded: false),
        ] + swiftFiles.map { $0.path() }

        return [
            .prebuildCommand(
                displayName: "SwiftLint \(target.name)",
                executable: swiftlintExecutable.url,
                arguments: arguments,
                environment: ["BUILD_WORKSPACE_DIRECTORY": workingDirectory.path(percentEncoded: false)],
                outputFilesDirectory: outputURL
            ),
        ]
    }

    /// .swiftlint.yml が存在するディレクトリを見つける（パッケージディレクトリから上の階層に向かって探す）
    private func findConfigDirectory(startingFrom directoryURL: URL) -> URL {
        var current = directoryURL.standardized
        while current.pathComponents.count > 1 {
            if FileManager.default.fileExists(atPath: current.appending(path: ".swiftlint.yml").path(percentEncoded: false)) {
                return current
            }
            current = current.deletingLastPathComponent()
        }
        return directoryURL
    }
}
