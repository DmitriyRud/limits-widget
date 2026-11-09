import Foundation

@testable import LimitsCore

/// Фейковый HTTP-клиент: фиксированный ответ или ошибка, запоминает запросы.
// @unchecked Sendable: изменяемый список запросов защищён NSLock.
final class FakeHTTPClient: HTTPClient, @unchecked Sendable {
    enum Outcome {
        case response(status: Int, body: Data)
        case failure(any Error)
    }

    struct Failure: Error {}

    private let outcome: Outcome
    private let lock = NSLock()
    private var recorded: [URLRequest] = []

    init(_ outcome: Outcome) { self.outcome = outcome }

    var requests: [URLRequest] { lock.withLock { recorded } }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lock.withLock { recorded.append(request) }
        switch outcome {
        case .failure(let error):
            throw error
        case .response(let status, let body):
            let url = request.url ?? URL(fileURLWithPath: "/")
            guard
                let response = HTTPURLResponse(
                    url: url, statusCode: status, httpVersion: nil, headerFields: nil)
            else { throw Failure() }
            return (body, response)
        }
    }
}
