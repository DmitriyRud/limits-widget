import Foundation

/// Тексты ошибок провайдеров для UI (одно место, на русском). Без токенов и данных пользователя.
extension ProviderStatus {
    public static let networkErrorMessage = "Ошибка сети"
    public static let formatChangedMessage = "Формат ответа изменился"
    public static let credentialsUnreadableMessage = "Не удалось прочитать учётные данные"

    /// Сообщение для неуспешного HTTP-кода (кроме 401/403).
    public static func httpErrorMessage(statusCode: Int) -> String {
        "Ошибка сервера (\(statusCode))"
    }
}
