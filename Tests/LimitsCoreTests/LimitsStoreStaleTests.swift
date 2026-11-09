import Foundation
import Testing

@testable import LimitsCore

@MainActor
@Suite("LimitsStore stale data")
struct LimitsStoreStaleTests {
    static let t1 = Date(timeIntervalSince1970: 1_800_000_000)
    static let t2 = Date(timeIntervalSince1970: 1_800_000_300)
    static let windows = [
        UsageWindow(
            kind: .session5h, usedPercent: 40,
            resetsAt: Date(timeIntervalSince1970: 1_800_010_000))
    ]

    @Test func failedRefreshKeepsPreviousOkSnapshotAndMarksStale() async {
        let p = SequencedProvider(
            id: "a", results: [(.ok, Self.windows, Self.t1), (.error("boom"), [], Self.t2)])
        let store = LimitsStore(providers: [p])
        await store.refresh()
        await store.refresh()
        #expect(store.snapshots.count == 1)
        #expect(store.snapshots[0].status == .ok)
        #expect(store.snapshots[0].windows == Self.windows)
        #expect(store.snapshots[0].fetchedAt == Self.t1)
        #expect(store.staleProviderIDs == ["a"])
    }

    @Test func successfulRefreshClearsStaleMark() async {
        let p = SequencedProvider(
            id: "a",
            results: [(.ok, Self.windows, Self.t1), (.noData, [], Self.t1), (.ok, Self.windows, Self.t2)])
        let store = LimitsStore(providers: [p])
        await store.refresh()
        await store.refresh()
        await store.refresh()
        #expect(store.staleProviderIDs.isEmpty)
        #expect(store.snapshots[0].fetchedAt == Self.t2)
    }

    @Test func errorWithoutPreviousDataIsKeptAsIs() async {
        let p = SequencedProvider(id: "a", results: [(.error("x"), [], Self.t1)])
        let store = LimitsStore(providers: [p])
        await store.refresh()
        #expect(store.snapshots[0].status == .error("x"))
        #expect(store.staleProviderIDs.isEmpty)
    }

    @Test func staleStateOfOneProviderDoesNotAffectAnother() async {
        let a = SequencedProvider(
            id: "a", results: [(.ok, Self.windows, Self.t1), (.error("x"), [], Self.t2)])
        let b = SequencedProvider(id: "b", results: [(.ok, Self.windows, Self.t1)])
        let store = LimitsStore(providers: [a, b])
        await store.refresh()
        await store.refresh()
        #expect(store.staleProviderIDs == ["a"])
        #expect(store.snapshots.map(\.providerID) == ["a", "b"])
    }

    @Test func refreshIntervalBelowMinimumIsClamped() async {
        let fixedNow = Self.t1
        let store = LimitsStore(
            providers: [], refreshInterval: .seconds(1), now: { fixedNow })
        #expect(store.refreshInterval == LimitsStore.minimumRefreshInterval)
        store.start()
        store.stop()
        #expect(store.now == Self.t1)
    }
}
