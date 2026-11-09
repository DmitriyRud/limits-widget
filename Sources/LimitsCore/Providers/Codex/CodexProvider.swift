import Foundation

/// Провайдер лимитов Codex CLI: сеть (`wham/usage`) с деградацией к локальным журналам сессий
/// (FR-003, FR-004, FR-008). Токен живёт только в локальной переменной на время запроса.
public struct CodexProvider: LimitsProvider {
    public let id = "codex"
    public let displayName = "Codex"

    /// Имя файла учётки внутри каталога Codex.
    private static let credentialsFileName = "auth.json"

    public static let usageURL: URL? = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "chatgpt.com"
        components.path = "/backend-api/wham/usage"
        return components.url
    }()

    private let codexHome: URL
    private let credentials: any CodexCredentialSource
    private let http: (any HTTPClient)?
    private let now: @Sendable () -> Date

    /// Сколько последних файлов проверять в поисках `rate_limits`.
    private static let maxFiles = 5
    /// Сколько каталогов-дат просматривать максимум.
    private static let maxDayDirectories = 14
    /// Читаем только хвост файла: последние события в конце.
    private static let tailBytes = 4 * 1024 * 1024

    public init(
        codexHome: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true),
        credentials: (any CodexCredentialSource)? = nil,
        http: (any HTTPClient)? = nil,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.codexHome = codexHome
        self.credentials =
            credentials
            ?? FileCodexCredentialSource(
                fileURL: codexHome.appendingPathComponent(Self.credentialsFileName))
        self.http = http
        self.now = now
    }

    public func fetchSnapshot() async -> ProviderSnapshot {
        switch await credentials.loadCodexCredentials() {
        case .noAuthFile:
            return snapshot(.notAuthenticated)
        case .noTokens, .unreadable:
            return await journalSnapshot(fallback: .noData)
        case .found(let creds):
            guard let http else { return await journalSnapshot(fallback: .noData) }
            return await fetchNetwork(creds, http: http)
        }
    }

    private func fetchNetwork(
        _ creds: CodexCredentials, http: any HTTPClient
    ) async -> ProviderSnapshot {
        guard let url = Self.usageURL else {
            return await journalSnapshot(fallback: .error(ProviderStatus.networkErrorMessage))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(creds.accessToken)", forHTTPHeaderField: "Authorization")
        if let account = creds.accountID {
            request.setValue(account, forHTTPHeaderField: "ChatGPT-Account-Id")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("LimitsWidget/0.1", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await http.send(request)
        } catch {
            return await journalSnapshot(fallback: .error(ProviderStatus.networkErrorMessage))
        }
        switch response.statusCode {
        case 200..<300:
            if let usage = try? CodexUsageResponse.decode(from: data) {
                return snapshot(.ok, windows: usage.windows())
            }
            return await journalSnapshot(fallback: .error(ProviderStatus.formatChangedMessage))
        case 401, 403:
            return await journalSnapshot(fallback: .tokenExpired)
        default:
            return await journalSnapshot(
                fallback: .error(ProviderStatus.httpErrorMessage(statusCode: response.statusCode)))
        }
    }

    private func snapshot(_ status: ProviderStatus, windows: [UsageWindow] = []) -> ProviderSnapshot {
        ProviderSnapshot(
            providerID: id, displayName: displayName, status: status,
            windows: windows, fetchedAt: now())
    }

    /// Данные из журналов; если сэмпла нет — снимок со статусом `fallback`.
    private func journalSnapshot(fallback: ProviderStatus) async -> ProviderSnapshot {
        let home = codexHome
        let sample: CodexRateLimitsSample? = await Task.detached {
            Self.loadSample(codexHome: home)
        }.value
        if let sample {
            return ProviderSnapshot(
                providerID: id, displayName: displayName, status: .ok,
                windows: sample.windows, fetchedAt: sample.fetchedAt)
        }
        return snapshot(fallback)
    }

    private static func loadSample(codexHome: URL) -> CodexRateLimitsSample? {
        let fm = FileManager.default
        for file in recentSessionFiles(in: codexHome, fm: fm) {
            guard let data = readTail(of: file) else { continue }
            if let sample = CodexSessionLogParser.latestSample(in: data) { return sample }
        }
        return nil
    }

    /// Самые свежие по mtime `rollout-*.jsonl` из последних каталогов `YYYY/MM/DD`.
    private static func recentSessionFiles(in codexHome: URL, fm: FileManager) -> [URL] {
        let root = codexHome.appendingPathComponent("sessions", isDirectory: true)
        var files: [(url: URL, mtime: Date)] = []
        var visitedDays = 0

        outer: for year in sortedSubdirectories(of: root, fm: fm) {
            for month in sortedSubdirectories(of: year, fm: fm) {
                for day in sortedSubdirectories(of: month, fm: fm) {
                    visitedDays += 1
                    let entries =
                        (try? fm.contentsOfDirectory(
                            at: day, includingPropertiesForKeys: [.contentModificationDateKey]))
                        ?? []
                    for url in entries
                    where url.lastPathComponent.hasPrefix("rollout-")
                        && url.pathExtension == "jsonl"
                    {
                        let mtime =
                            (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                            .contentModificationDate ?? .distantPast
                        files.append((url, mtime))
                    }
                    if files.count >= maxFiles || visitedDays >= maxDayDirectories {
                        break outer
                    }
                }
            }
        }
        return files.sorted { $0.mtime > $1.mtime }.prefix(maxFiles).map(\.url)
    }

    private static func sortedSubdirectories(of url: URL, fm: FileManager) -> [URL] {
        let entries =
            (try? fm.contentsOfDirectory(
                at: url, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        return
            entries
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    private static func readTail(of url: URL) -> Data? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        guard let size = try? handle.seekToEnd() else { return nil }
        let start = size > UInt64(tailBytes) ? size - UInt64(tailBytes) : 0
        guard (try? handle.seek(toOffset: start)) != nil else { return nil }
        return try? handle.readToEnd()
    }
}
