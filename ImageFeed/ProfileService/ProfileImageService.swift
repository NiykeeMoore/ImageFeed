import Foundation

private struct UserResult: Codable {
    let profileImage: ProfileImage
}

private struct ProfileImage: Codable {
    let small: String
    let medium: String
    let large: String
}

final class ProfileImageService {
    
    private var task: URLSessionTask?
    private(set) var avatarURL: String?
    static let shared = ProfileImageService()
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    private let urlSession = URLSession.shared
    private let oAuthTokenStorage = OAuth2TokenStorage()
    
    private init(task: URLSessionTask? = nil, avatarURL: String? = nil) {
        self.task = task
        self.avatarURL = avatarURL
    }
    
    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void ) {
        assert(Thread.isMainThread)
        task?.cancel()
        
        guard var request = URLRequest.makeHTTPRequest(path: "/users/\(username)", httpMethod: "GET", baseURL: "\(DefaultBaseURL)"),
              let token = oAuthTokenStorage.token else {
                  print("[fetchProfileImageURL]: RequestError - Ошибка создания запроса для юзера: \(username)")
                  completion(.failure(NSError(domain: "ProfileImageServiceError", code: -1, userInfo: nil)))
                  return
              }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            guard let self else { return }
            
            switch result {
            case .success(let user):
                self.avatarURL = user.profileImage.large
                print("[fetchProfileImageURL]: Success - URL: \(user.profileImage.large)")
                completion(.success(user.profileImage.large))
                NotificationCenter.default.post(name: ProfileImageService.didChangeNotification,
                                                object: self,
                                                userInfo: ["URL": user.profileImage.large])
            case .failure(let error):
                print("[fetchProfileImageURL]: NetworkError - \(error.localizedDescription), Username: \(username)")
                completion(.failure(error))
            }
            self.task = nil
        }
        self.task = task
        task.resume()
    }
}
