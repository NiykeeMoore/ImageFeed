import Foundation

protocol ProfileImageServiceProtocol {
    var avatarURL: String? { get }
    func fetchProfileImageURL(_ username: String, completion: @escaping (Result<String, Error>) -> Void)
}

final class ProfileImageService: ProfileImageServiceProtocol {
    
    static let shared = ProfileImageService()
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    private let oAuthTokenStorage = OAuth2TokenStorage()
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private(set) var avatarURL: String?
    
    private init() {}
    
    func fetchProfileImageURL(_ username: String, completion: @escaping (Result<String, Error>) -> Void ) {
        assert(Thread.isMainThread)
        task?.cancel()
        
        guard let request = URLRequest.makeHTTPRequest(path: "/users/\(username)",
                                                       httpMethod: "GET",
                                                       baseURL: String(describing: Constants.defaultBaseURL)) else {
            assertionFailure("Failed to make HTTP request")
            return
        }
        let task = urlSession.objectTask(for: request) { [weak self] (result:Result<UserResult, Error>) in
            guard let self else { return }
            
            switch result {
            case .success(let user):
                completion(.success(user.profileImage.large))
                NotificationCenter.default.post(name: ProfileImageService.didChangeNotification,
                                                object: self,
                                                userInfo: ["URL": user.profileImage.large])
                self.avatarURL = user.profileImage.large
            case .failure(let error):
                completion(.failure(error))
            }
            self.task = nil
        }
        self.task = task
        task.resume()
    }
}
