import Foundation

@testable import LimitsCore

/// Фейковый источник учётных данных с фиксированным результатом.
struct FakeCredentialSource: CredentialSource {
    let result: ClaudeCredentialsResult

    func loadClaudeCredentials() async -> ClaudeCredentialsResult { result }
}
