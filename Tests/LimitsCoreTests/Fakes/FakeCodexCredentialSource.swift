import Foundation

@testable import LimitsCore

/// Фейковый источник учётных данных Codex с фиксированным результатом.
struct FakeCodexCredentialSource: CodexCredentialSource {
    let result: CodexCredentialsResult

    func loadCodexCredentials() async -> CodexCredentialsResult { result }
}
