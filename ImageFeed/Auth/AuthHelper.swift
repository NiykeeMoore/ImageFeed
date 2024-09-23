import Foundation

protocol AuthHelperProtocol {
    func authRequest() -> URLRequest
    func code(from url: URL) -> String?
}

final class AuthHelper: AuthHelperProtocol {
    
    func authRequest() -> URLRequest {
        let url = authURL()
        return URLRequest(url: url)
    }
    
    func authURL() -> URL {
        guard var urlComponents = URLComponents(string: Constants.authorizeURLString) else {
            fatalError("Incorrect base URL")
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        return urlComponents.url!
    }
    
    func code(from url: URL) -> String? {
        if let urlComponents = URLComponents(string: url.absoluteString),
           urlComponents.path == "/oauth/authorize/native",
           let queryItems = urlComponents.queryItems,
           let codeItem = queryItems.first(where: { $0.name == "code" })
        {
            return codeItem.value
        } else {
            return nil
        }
    }
}
