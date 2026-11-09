import Foundation

/// Состояние провайдера, которое понимает UI.
public enum ProviderStatus: Hashable, Sendable {
    case ok
    case notAuthenticated
    case tokenExpired
    case noData
    case error(String)
}

/// Снимок лимитов одного ИИ-агента на момент `fetchedAt`.
public struct ProviderSnapshot: Hashable, Sendable, Identifiable {
    public var id: String { providerID }

    public let providerID: String
    public let displayName: String
    public let status: ProviderStatus
    public let windows: [UsageWindow]
    public let fetchedAt: Date

    public init(
        providerID: String,
        displayName: String,
        status: ProviderStatus,
        windows: [UsageWindow] = [],
        fetchedAt: Date = .now
    ) {
        self.providerID = providerID
        self.displayName = displayName
        self.status = status
        self.windows = windows
        self.fetchedAt = fetchedAt
    }
}
