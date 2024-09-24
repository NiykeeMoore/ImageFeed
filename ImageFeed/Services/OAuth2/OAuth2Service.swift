import Foundation

final class OAuth2Service {
    
    static let shared = OAuth2Service()
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    private(set) var authToken: String? {
        get {
            return OAuth2TokenStorage().token
        }
        set {
            OAuth2TokenStorage().token = newValue
        }
    }
    
    private init(task: URLSessionTask? = nil, lastCode: String? = nil) {
        self.task = task
        self.lastCode = lastCode
    }
    
    func fetchAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        if lastCode == code {
            completion(.failure("Error code: \(code)" as! Error))
            return
        }
        task?.cancel()
        lastCode = code
        
        guard let request = makeRequest(code: code) else {
            completion(.failure("Failed to make request \(code)" as! Error))
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let tokenResponseBody):
                completion(.success(tokenResponseBody.accessToken))
            case .failure(let error):
                self.lastCode = nil
                completion(.failure(error))
            }
            self.task = nil
        }
        self.task = task
        task.resume()
    }
}

// MARK: - Shared helpers
private extension OAuth2Service {
    func makeRequest(code: String) -> URLRequest? {
        guard let url = URL(string: "\(Constants.authorizeURLString)"),
              let request = URLRequest.makeHTTPRequest(
                path: "/oauth/token"
                + "?client_id=\(Constants.accessKey)"
                + "&&client_secret=\(Constants.secretKey)"
                + "&&redirect_uri=\(Constants.redirectURI)"
                + "&&code=\(code)"
                + "&&grant_type=authorization_code",
                httpMethod: "POST",
                baseURL: "\(url)")
        else {
            return nil
        }
        return request
    }
}
