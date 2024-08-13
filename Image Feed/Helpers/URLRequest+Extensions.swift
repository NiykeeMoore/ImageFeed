import Foundation

extension URLRequest {
    static func makeHTTPRequest(
        path: String,
        httpMethod: String,
        baseURL: URL = DefaultBaseURL
    ) -> URLRequest? {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        return request
    }
}
