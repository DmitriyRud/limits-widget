import Foundation

@testable import LimitsCore

/// Фейк, отдающий заранее заданные снимки по очереди (последний повторяется).
// @unchecked Sendable: индекс вызова защищён NSLock; остальное — let.
final class SequencedProvider: LimitsProvider, @unchecked Sendable {
    let id: String
    let displayName: String
    private let snapshots: [ProviderSnapshot]
    private let lock = NSLock()
    private var index = 0

    init(id: String, results: [(ProviderStatus, [UsageWindow], Date)]) {
        self.id = id
        self.displayName = "Seq \(id)"
        self.snapshots = results.map {
            ProviderSnapshot(
                providerID: id, displayName: "Seq \(id)", status: $0.0, windows: $0.1,
                fetchedAt: $0.2)
        }
    }

    func fetchSnapshot() async -> ProviderSnapshot {
        lock.withLock {
            let snapshot = snapshots[min(index, snapshots.count - 1)]
            index += 1
            return snapshot
        }
    }
}
