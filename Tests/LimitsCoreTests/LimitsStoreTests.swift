import Foundation
import Testing

@testable import LimitsCore

@MainActor
@Suite("LimitsStore")
struct LimitsStoreTests {
    static let reset = Date(timeIntervalSince1970: 1_800_010_000)
    static let okWindows = [
        UsageWindow(kind: .session5h, usedPercent: 40, resetsAt: reset),
        UsageWindow(kind: .weekly, usedPercent: 10, resetsAt: reset),
    ]

    @Test func snapshotsAreEmptyBeforeFirstRefresh() {
        let store = LimitsStore(providers: [FakeProvider(id: "a")])
        #expect(store.snapshots.isEmpty)
    }

    @Test func emptyProviderListYieldsEmptySnapshots() async {
        let store = LimitsStore(providers: [])
        await store.refresh()
        #expect(store.snapshots.isEmpty)
    }

    // NFR-003: сбой одного провайдера не влияет на других.
    @Test func failingProviderDoesNotAffectOthers() async {
        let store = LimitsStore(providers: [
            FakeProvider(id: "a", windows: Self.okWindows),
            FakeProvider(id: "b", status: .error("boom")),
            FakeProvider(id: "c", windows: Self.okWindows),
        ])
        await store.refresh()
        #expect(store.snapshots.map(\.providerID) == ["a", "b", "c"])
        #expect(store.snapshots[0].status == .ok)
        #expect(store.snapshots[0].windows == Self.okWindows)
        #expect(store.snapshots[1].status == .error("boom"))
        #expect(store.snapshots[2].status == .ok)
        #expect(store.snapshots[2].windows == Self.okWindows)
    }

    @Test func notAuthenticatedProviderDoesNotAffectOthers() async {
        let store = LimitsStore(providers: [
            FakeProvider(id: "a", status: .notAuthenticated),
            FakeProvider(id: "b", windows: Self.okWindows),
        ])
        await store.refresh()
        #expect(store.snapshots.count == 2)
        #expect(store.snapshots[0].status == .notAuthenticated)
        #expect(store.snapshots[1].status == .ok)
        #expect(store.snapshots[1].windows == Self.okWindows)
    }

    // NFR-003: медленный провайдер не блокирует/не теряет остальных; порядок сохраняется.
    @Test func orderFollowsProvidersRegardlessOfResponseTime() async {
        let store = LimitsStore(providers: [
            FakeProvider(id: "slow", windows: Self.okWindows, delayMilliseconds: 50),
            FakeProvider(id: "fast", windows: Self.okWindows),
            FakeProvider(id: "mid", status: .error("x"), delayMilliseconds: 20),
        ])
        await store.refresh()
        #expect(store.snapshots.map(\.providerID) == ["slow", "fast", "mid"])
    }

    @Test func repeatedRefreshReplacesSnapshots() async {
        let a = FakeProvider(id: "a", windows: Self.okWindows)
        let b = FakeProvider(id: "b")
        let store = LimitsStore(providers: [a, b])
        await store.refresh()
        let first = store.snapshots
        await store.refresh()
        #expect(store.snapshots.count == 2)
        #expect(a.callCount == 2)
        #expect(b.callCount == 2)
        #expect(store.snapshots[0].fetchedAt > first[0].fetchedAt)
        #expect(store.snapshots.map(\.providerID) == ["a", "b"])
    }
}
