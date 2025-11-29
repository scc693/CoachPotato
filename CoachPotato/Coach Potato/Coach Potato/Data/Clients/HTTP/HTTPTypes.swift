import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH
}

struct HTTPRequest {
    let url: URL
    let method: HTTPMethod
    var headers: [String: String]
    var body: Data?

    init(url: URL, method: HTTPMethod = .GET, headers: [String: String] = [:], body: Data? = nil) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }
}

enum HTTPError: Error {
    case networkFailure(Error)
    case invalidResponse
    case decodingError(Error)
    case statusCode(Int)
}
