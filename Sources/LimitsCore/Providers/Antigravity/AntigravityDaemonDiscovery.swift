import Foundation

/// Метаданные локального демона Antigravity 2.0 (`~/.gemini/antigravity/daemon/hub_*.json`).
/// Только чтение; `csrfToken` скрыт во всех текстовых представлениях (NFR-001, NFR-002).
public struct AntigravityHubInfo: Sendable, CustomStringConvertible,
    CustomDebugStringConvertible, CustomReflectable
{
    public let httpsPort: Int?
    public let httpPort: Int?
    public let pid: Int?
    /// Не `public`: токен нужен только провайдеру внутри LimitsCore (NFR-001).
    let csrfToken: String

    public init(httpsPort: Int?, httpPort: Int?, pid: Int?, csrfToken: String) {
        self.httpsPort = httpsPort
        self.httpPort = httpPort
        self.pid = pid
        self.csrfToken = csrfToken
    }

    private struct Raw: Decodable {
        let httpsPort: Int?
        let httpPort: Int?
        let pid: Int?
        let csrfToken: String
    }

    public static func decode(from data: Data) throws -> AntigravityHubInfo {
        let raw = try JSONDecoder().decode(Raw.self, from: data)
        return AntigravityHubInfo(
            httpsPort: raw.httpsPort,
            httpPort: raw.httpPort,
            pid: raw.pid,
            csrfToken: raw.csrfToken
        )
    }

    /// URL для запроса `GetUserStatus` строго на `127.0.0.1` (предпочтительно HTTPS).
    func endpointURL(path: String) -> URL? {
        if let httpsPort, httpsPort > 0 {
            return URL(string: "https://127.0.0.1:\(httpsPort)\(path)")
        }
        if let httpPort, httpPort > 0 {
            return URL(string: "http://127.0.0.1:\(httpPort)\(path)")
        }
        return nil
    }

    public var description: String { "AntigravityHubInfo(<redacted>)" }
    public var debugDescription: String { "AntigravityHubInfo(<redacted>)" }
    public var customMirror: Mirror { Mirror(self, children: [], displayStyle: .struct) }
}

/// Абстракция обнаружения запущенных локальных хабов Antigravity (V.3).
public protocol AntigravityDaemonDiscovery: Sendable {
    func discoverHubs() -> [AntigravityHubInfo]
}

/// Читает `hub_*.json` из `~/.gemini/antigravity/daemon/` в порядке убывания `mtime` (только чтение).
public struct FileAntigravityDaemonDiscovery: AntigravityDaemonDiscovery {
    private let daemonDirectory: URL

    public init(
        daemonDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".gemini/antigravity/daemon", isDirectory: true)
    ) {
        self.daemonDirectory = daemonDirectory
    }

    public func discoverHubs() -> [AntigravityHubInfo] {
        let fm = FileManager.default
        guard
            let urls = try? fm.contentsOfDirectory(
                at: daemonDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }

        let hubFiles = urls.filter { url in
            let name = url.lastPathComponent
            return name.hasPrefix("hub_") && name.hasSuffix(".json")
        }

        let sorted = hubFiles.sorted { lhs, rhs in
            let lDate =
                (try? lhs.resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate) ?? .distantPast
            let rDate =
                (try? rhs.resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate) ?? .distantPast
            return lDate > rDate
        }

        return sorted.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? AntigravityHubInfo.decode(from: data)
        }
    }
}
