//
//  CLIProcessTests.swift
//  AgentToolsPackage
//

import Foundation
import HometeIntrospection
import Testing

/// `homete-cli`のプロセスの、標準入力・標準出力のJSONの入出力
struct CLIProcessTests {

    @Test("標準入力のコマンドごとに、標準出力へ1行ずつJSONを返し、受け付けられない操作もJSONで返す")
    func roundTrip() throws {
        // Arrange

        let input = """
        do {"action":"complete","arguments":{"id":"laundry"}}
        do {"action":"unknown"}
        quit

        """

        // Act

        let lines = try runCLI(arguments: ["--scenario", "today"], input: input)

        // Assert

        let responses = try lines.map { try JSONDecoder().decode(CLIResponse.self, from: Data($0.utf8)) }
        #expect(responses.map(\.ok) == [true, false])
        #expect(responses.first?.snapshot?.currentScreen == .houseworkComplete)
        #expect(responses.last?.error?.code == .unknownAction)
    }

    // MARK: - Helper

    /// ビルドした`homete-cli`を起動し、標準出力の行を返す
    private func runCLI(arguments: [String], input: String) throws -> [String] {
        let process = Process()
        process.executableURL = Self.productsDirectory.appendingPathComponent("homete-cli")
        process.arguments = arguments
        let stdin = Pipe()
        let stdout = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = Pipe()
        try process.run()
        stdin.fileHandleForWriting.write(Data(input.utf8))
        try stdin.fileHandleForWriting.close()
        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let output = String(bytes: data, encoding: .utf8) ?? ""
        return output.split(separator: "\n").map(String.init)
    }

    /// `swift build`・`swift test`がビルドした成果物のディレクトリ（AgentToolsPackage/.build/debug）
    private static var productsDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(".build/debug")
    }

}
