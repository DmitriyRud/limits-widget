import Foundation

/// Провайдер лимитов Antigravity 2.0 через локальный `agy --hub` (FR-001…FR-006).
/// Приоритет — `RetrieveUserQuotaSummary` (все пулы и окна 5 ч / Неделя),
/// фоллбэк — `GetUserStatus` (агрегированный минимум по моделям).
/// Работает локально по `127.0.0.1` без выхода в интернет; CSRF-токен не логируется.
public struct AntigravityProvider: LimitsProvider {
    public let id = "antigravity"
    public let displayName = "Antigravity"

    static let quotaSummaryPath =
        "/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary"
    static let statusPath = "/exa.language_server_pb.LanguageServerService/GetUserStatus"

    private static let emptyBody = Data("{}".utf8)
    private static let statusRequestBody = Data(
        #"{"metadata":{"ideName":"antigravity","extensionName":"antigravity","locale":"en"}}"#.utf8)

    private let discovery: any AntigravityDaemonDiscovery
    private let client: any AntigravityLocalClient
    private let now: @Sendable () -> Date

    public init(
        discovery: any AntigravityDaemonDiscovery = FileAntigravityDaemonDiscovery(),
        client: any AntigravityLocalClient = LoopbackAntigravityLocalClient(),
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.discovery = discovery
        self.client = client
        self.now = now
    }

    public func fetchSnapshot() async -> ProviderSnapshot {
        let hubs = discovery.discoverHubs()
        guard !hubs.isEmpty else { return snapshot(.noData) }

        for hub in hubs {
            if let result = await fetchFromHub(hub) {
                return result
            }
        }

        // Ни один из найденных hub_*.json не ответил (Antigravity закрыт).
        return snapshot(.noData)
    }

    /// Возвращает `nil`, если хаб недоступен по сети (устаревший `hub_*.json`) — пробуем следующий.
    private func fetchFromHub(_ hub: AntigravityHubInfo) async -> ProviderSnapshot? {
        guard let summaryReq = makeRequest(hub: hub, path: Self.quotaSummaryPath, body: Self.emptyBody)
        else { return nil }

        let summaryData: Data
        let summaryHTTP: HTTPURLResponse
        do {
            (summaryData, summaryHTTP) = try await client.send(summaryReq, hub: hub)
        } catch {
            return nil
        }

        switch summaryHTTP.statusCode {
        case 200..<300:
            if let parsed = try? AntigravityQuotaSummaryResponse.decode(from: summaryData) {
                let currentNow = now()
                let windows = parsed.windows(now: currentNow)
                if !windows.isEmpty {
                    return ProviderSnapshot(
                        providerID: id, displayName: displayName, status: .ok,
                        windows: windows, fetchedAt: currentNow)
                }
            }
            // Если сводка пуста или формат изменился — пробуем фоллбэк GetUserStatus.
            return await fetchLegacyStatus(hub: hub)
        case 401, 403:
            return snapshot(.notAuthenticated)
        case 404, 501:
            // Старая версия хаба без RetrieveUserQuotaSummary — фоллбэк на GetUserStatus.
            return await fetchLegacyStatus(hub: hub)
        default:
            return snapshot(
                .error(ProviderStatus.httpErrorMessage(statusCode: summaryHTTP.statusCode)))
        }
    }

    private func fetchLegacyStatus(hub: AntigravityHubInfo) async -> ProviderSnapshot {
        guard
            let statusReq = makeRequest(
                hub: hub, path: Self.statusPath, body: Self.statusRequestBody)
        else {
            return snapshot(.noData)
        }

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await client.send(statusReq, hub: hub)
        } catch {
            return snapshot(.noData)
        }

        switch response.statusCode {
        case 200..<300:
            break
        case 401, 403:
            return snapshot(.notAuthenticated)
        default:
            return snapshot(.error(ProviderStatus.httpErrorMessage(statusCode: response.statusCode)))
        }

        guard let parsed = try? AntigravityUsageResponse.decode(from: data) else {
            return snapshot(.error(ProviderStatus.formatChangedMessage))
        }
        let currentNow = now()
        let windows = parsed.windows(now: currentNow)
        guard !windows.isEmpty else { return snapshot(.noData) }
        return ProviderSnapshot(
            providerID: id, displayName: displayName, status: .ok,
            windows: windows, fetchedAt: currentNow)
    }

    private func makeRequest(hub: AntigravityHubInfo, path: String, body: Data) -> URLRequest? {
        guard let url = hub.endpointURL(path: path) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
        request.setValue(hub.csrfToken, forHTTPHeaderField: "X-Codeium-Csrf-Token")
        return request
    }

    private func snapshot(_ status: ProviderStatus, windows: [UsageWindow] = []) -> ProviderSnapshot
    {
        ProviderSnapshot(
            providerID: id, displayName: displayName, status: status,
            windows: windows, fetchedAt: now())
    }
}
