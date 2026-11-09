import Foundation

@testable import LimitsCore

/// Фейковый провайдер: фиксированный снимок, ограниченная задержка, счётчик вызовов.
// @unchecked Sendable: изменяемый счётчик вызовов защищён NSLock; остальные свойства — let.
final class FakeProvider: LimitsProvider, @unchecked Sendable {
    let id: String
    let displayName: String
    private let status: ProviderStatus
    private let windows: [UsageWindow]
    private let delayMilliseconds: Int
    private let fetchedAt: Date
    private let lock = NSLock()
    private var calls = 0

    init(
        id: String,
        status: ProviderStatus = .ok,
        windows: [UsageWindow] = [],
        delayMilliseconds: Int = 0,
        fetchedAt: Date = Date(timeIntervalSince1970: 1_800_000_000)
    ) {
        self.id = id
        self.displayName = "Fake \(id)"
        self.status = status
        self.windows = windows
        self.delayMilliseconds = delayMilliseconds
        self.fetchedAt = fetchedAt
    }

    var callCount: Int {
        lock.withLock { calls }
    }

    func fetchSnapshot() async -> ProviderSnapshot {
        let n = lock.withLock {
            calls += 1
            return calls
        }
        if delayMilliseconds > 0 {
            try? await Task.sleep(for: .milliseconds(delayMilliseconds))
        }
        // Номер вызова отражаем в fetchedAt, чтобы отличать снимки между refresh.
        return ProviderSnapshot(
            providerID: id, displayName: displayName, status: status,
            windows: windows, fetchedAt: fetchedAt.addingTimeInterval(TimeInterval(n)))
    }
}
