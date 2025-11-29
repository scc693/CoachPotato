import Foundation

protocol HTTPClient {
    func send<T: Decodable & Sendable>(_ request: HTTPRequest, decodeTo type: T.Type) async throws -> T
}

final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func send<T: Decodable & Sendable>(_ request: HTTPRequest, decodeTo type: T.Type) async throws -> T {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.allHTTPHeaderFields = request.headers
        urlRequest.httpBody = request.body

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw HTTPError.networkFailure(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw HTTPError.statusCode(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw HTTPError.decodingError(error)
        }
    }
}
