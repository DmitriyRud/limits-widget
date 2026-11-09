import Foundation

/// Результат чтения учётных данных Claude Code (FR-001).
public enum ClaudeCredentialsResult: Sendable {
    case found(ClaudeCredentials)
    /// Учётных данных нет (пользователь не авторизован).
    case notFound
    /// Данные есть, но прочитать/разобрать их не удалось.
    case unreadable
}

/// Источник учётных данных. Только чтение, не бросает ошибок наружу (NFR-001).
public protocol CredentialSource: Sendable {
    func loadClaudeCredentials() async -> ClaudeCredentialsResult
}

/// Чтение Keychain через `/usr/bin/security` (research R-3, security.md п.7).
/// stdout декодируется сразу и нигде не сохраняется и не логируется; stderr отбрасывается.
public struct KeychainCredentialSource: CredentialSource {
    public static let serviceName = "Claude Code-credentials"
    private let executablePath: String
    private let arguments: [String]

    public init() {
        self.init(
            executablePath: "/usr/bin/security",
            arguments: ["find-generic-password", "-s", Self.serviceName, "-w"])
    }

    /// Для тестов: подмена исполняемого файла.
    init(executablePath: String, arguments: [String]) {
        self.executablePath = executablePath
        self.arguments = arguments
    }

    public func loadClaudeCredentials() async -> ClaudeCredentialsResult {
        let path = executablePath
        let args = arguments
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: Self.run(path: path, arguments: args))
            }
        }
    }

    /// Максимальное время работы `/usr/bin/security`.
    static let timeout: TimeInterval = 60

    private static func run(path: String, arguments: [String]) -> ClaudeCredentialsResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return .notFound
        }
        // Таймаут: `security` может зависнуть (например, на системном диалоге доступа к Keychain).
        // Запас большой, чтобы пользователь успел нажать «Всегда разрешать» (R-3).
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) {
            if process.isRunning { process.terminate() }
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        try? pipe.fileHandleForReading.close()
        if process.terminationReason == .uncaughtSignal { return .unreadable }
        guard process.terminationStatus == 0 else { return .notFound }
        guard let credentials = try? ClaudeCredentials.decode(from: data) else {
            return .unreadable
        }
        return .found(credentials)
    }
}

/// Фоллбэк: чтение файла `~/.claude/.credentials.json`. Только чтение (путь инъецируется).
public struct FileCredentialSource: CredentialSource {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Стандартный путь `~/.claude/.credentials.json`.
    public static func standard() -> FileCredentialSource {
        FileCredentialSource(
            fileURL: FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".claude/.credentials.json"))
    }

    public func loadClaudeCredentials() async -> ClaudeCredentialsResult {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .notFound }
        guard let data = try? Data(contentsOf: fileURL),
            let credentials = try? ClaudeCredentials.decode(from: data)
        else { return .unreadable }
        return .found(credentials)
    }
}

/// Пробует источники по порядку: первый `.found` побеждает.
/// Если нигде не найдено, но какой-то источник нечитаем — `.unreadable`, иначе `.notFound`.
public struct ChainedCredentialSource: CredentialSource {
    private let sources: [any CredentialSource]

    public init(_ sources: [any CredentialSource]) {
        self.sources = sources
    }

    /// Keychain, затем файл.
    public static func standard() -> ChainedCredentialSource {
        ChainedCredentialSource([KeychainCredentialSource(), FileCredentialSource.standard()])
    }

    public func loadClaudeCredentials() async -> ClaudeCredentialsResult {
        var sawUnreadable = false
        for source in sources {
            switch await source.loadClaudeCredentials() {
            case .found(let credentials): return .found(credentials)
            case .unreadable: sawUnreadable = true
            case .notFound: break
            }
        }
        return sawUnreadable ? .unreadable : .notFound
    }
}
