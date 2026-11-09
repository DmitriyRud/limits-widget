import Foundation
import Observation

/// Агрегатор снимков всех провайдеров (FR-006, FR-008, FR-012, NFR-003).
///
/// Данные обновляются раз в `refreshInterval`; `now` обновляется раз в минуту,
/// чтобы UI пересчитывал обратный отсчёт без сети.
@MainActor
@Observable
public final class LimitsStore {
    public private(set) var snapshots: [ProviderSnapshot] = []
    /// Текущее время для UI; обновляется раз в 60 с.
    public private(set) var now: Date
    /// Провайдеры, чьё последнее обновление не удалось: показан прежний `.ok`-снимок (FR-008).
    public private(set) var staleProviderIDs: Set<String> = []

    @ObservationIgnored private let providers: [any LimitsProvider]
    @ObservationIgnored private let brandings: [String: ProviderBranding]
    @ObservationIgnored public let refreshInterval: Duration
    @ObservationIgnored private let clock: @Sendable () -> Date
    @ObservationIgnored private var dataTask: Task<Void, Never>?
    @ObservationIgnored private var tickTask: Task<Void, Never>?

    /// Минимальный интервал обновления данных — 60 с (FR-006).
    public static let minimumRefreshInterval: Duration = .seconds(60)

    public init(
        providers: [any LimitsProvider],
        refreshInterval: Duration = .seconds(300),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.providers = providers
        self.brandings = providers.reduce(into: [:]) { result, provider in
            if let branding = provider.branding { result[provider.id] = branding }
        }
        self.refreshInterval = max(refreshInterval, Self.minimumRefreshInterval)
        self.clock = now
        self.now = now()
    }

    /// Логотип провайдера по его id (FR-005, IV.2); `nil`, если логотипа нет.
    public func branding(for providerID: String) -> ProviderBranding? {
        brandings[providerID]
    }

    /// Опрашивает всех провайдеров конкурентно; порядок результата = порядок провайдеров.
    public func refresh() async {
        let results = await withTaskGroup(of: (Int, ProviderSnapshot).self) { group in
            for (index, provider) in providers.enumerated() {
                group.addTask { (index, await provider.fetchSnapshot()) }
            }
            var collected: [(Int, ProviderSnapshot)] = []
            for await item in group { collected.append(item) }
            return collected.sorted { $0.0 < $1.0 }.map(\.1)
        }

        let previous = Dictionary(
            snapshots.map { ($0.providerID, $0) }, uniquingKeysWith: { _, last in last })
        var stale = Set<String>()
        var merged: [ProviderSnapshot] = []
        for snapshot in results {
            if snapshot.status != .ok, let old = previous[snapshot.providerID], old.status == .ok {
                merged.append(old)
                stale.insert(snapshot.providerID)
            } else {
                merged.append(snapshot)
            }
        }
        snapshots = merged
        staleProviderIDs = stale
        now = clock()
    }

    /// Запускает периодическое обновление данных и минутный тик времени.
    public func start() {
        guard dataTask == nil else { return }
        let interval = refreshInterval
        dataTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: interval)
            }
        }
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                if Task.isCancelled { break }
                self?.tick()
            }
        }
    }

    public func stop() {
        dataTask?.cancel()
        tickTask?.cancel()
        dataTask = nil
        tickTask = nil
    }

    private func tick() {
        now = clock()
    }
}
