//
//  HometeCLI.swift
//  AgentToolsPackage
//

import Foundation
import HometeIntrospection
import HometeScenarioSupport

/// HometeAppCoreのViewModelを、シミュレーターを起動せずに動かすCLI（doc/tech/agent-cli.md）
@main
enum HometeCLI {

    @MainActor
    static func main() async {
        // Storeなどが`print`で出す診断を標準エラー出力へ回し、標準出力はJSONだけにする
        standardOutput = FileHandle(fileDescriptor: dup(STDOUT_FILENO), closeOnDealloc: true)
        dup2(STDERR_FILENO, STDOUT_FILENO)

        var arguments = Array(CommandLine.arguments.dropFirst())
        if arguments.contains("--help") || arguments.contains("-h") {
            printToStandardError(usage)
            return
        }
        if arguments.first == "scenarios" {
            output(CLIResponse(scenarios: scenarioSummaries))
            return
        }

        var scenarioName = Scenario.today.name
        if let index = arguments.firstIndex(of: "--scenario") {
            guard arguments.indices.contains(index + 1) else {
                printToStandardError("--scenario にシナリオ名を指定してください")
                exit(64)
            }
            scenarioName = arguments[index + 1]
            arguments.removeSubrange(index ... (index + 1))
        }
        guard arguments.isEmpty else {
            printToStandardError("不明な引数: \(arguments.joined(separator: " "))\n\n\(usage)")
            exit(64)
        }
        guard let scenario = Scenario.named(scenarioName) else {
            let names = Scenario.all.map(\.name).joined(separator: ", ")
            printToStandardError("シナリオ \(scenarioName) はありません（\(names)）")
            exit(64)
        }

        let environment = scenario.makeEnvironment()
        let introspector = AppIntrospector(session: environment.session)
        await introspector.settle()
        printToStandardError("scenario: \(scenario.name)（コマンド: ls / do <JSON> / scenarios / quit）")

        // 標準入力の読み込みはMainActorの外で待ち、MainActorを占有しない
        for await line in standardInputLines() {
            let command = line.trimmingCharacters(in: .whitespaces)
            if command.isEmpty { continue }
            if command == "quit" || command == "exit" { break }
            let response = await handle(command, introspector: introspector)
            output(response)
        }
    }

}

private extension HometeCLI {

    /// JSONを書き出す、元の標準出力
    nonisolated(unsafe) static var standardOutput = FileHandle.standardOutput

    static let usage = """
    使い方: homete-cli [--scenario <名前>]
           homete-cli scenarios

    標準入力から1行に1つのコマンドを受け取り、標準出力へ1行に1つのJSONを返します。
      ls             今の画面・状態・実行できる操作を出す
      do <JSON>      操作を実行し、非同期の処理が終わった後の状態を出す
                     例: do {"action":"complete","arguments":{"id":"laundry"}}
      scenarios      選べるシナリオを出す
      quit           終了する
    """

    static var scenarioSummaries: [CLIResponse.ScenarioSummary] {
        Scenario.all.map { .init(name: $0.name, summary: $0.summary) }
    }

    @MainActor
    static func handle(_ command: String, introspector: AppIntrospector) async -> CLIResponse {
        let (verb, rest) = split(command)
        switch verb {
        case "ls":
            return CLIResponse(snapshot: introspector.snapshot())

        case "do":
            let request: ActionRequest
            do {
                request = try JSONDecoder().decode(ActionRequest.self, from: Data(rest.utf8))
            } catch {
                return CLIResponse(error: .init(code: .invalidRequest, message: "操作のJSONを読めません: \(rest)"))
            }
            do {
                try introspector.perform(request)
            } catch {
                return CLIResponse(error: error)
            }
            await introspector.settle()
            return CLIResponse(snapshot: introspector.snapshot())

        case "scenarios":
            return CLIResponse(scenarios: scenarioSummaries)

        default:
            return CLIResponse(error: .init(code: .invalidRequest, message: "不明なコマンド: \(verb)"))
        }
    }

    static func split(_ command: String) -> (verb: String, rest: String) {
        guard let space = command.firstIndex(of: " ") else { return (command, "") }
        return (String(command[..<space]), String(command[command.index(after: space)...]))
    }

    static func standardInputLines() -> AsyncStream<String> {
        AsyncStream { continuation in
            Thread.detachNewThread {
                while let line = readLine() {
                    continuation.yield(line)
                }
                continuation.finish()
            }
        }
    }

    static func output(_ response: CLIResponse) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        do {
            let data = try encoder.encode(response)
            standardOutput.write(data + Data("\n".utf8))
        } catch {
            printToStandardError("JSONにできませんでした: \(error)")
        }
    }

    static func printToStandardError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }

}
