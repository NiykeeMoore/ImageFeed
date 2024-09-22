import Foundation

final class ImagesListService {
    static let shared = ImagesListService()
    private let tokenStorage = OAuth2TokenStorage()
    var photos: [Photo] = []
    private var task: URLSessionTask?
    private let urlSession = URLSession.shared
    private var lastLoadedPage: Int?
    private let dateFormatter = ISO8601DateFormatter()
    init() {}
    
    private func makeImagesListRequest(page: Int) -> URLRequest? {
        let per_page = 10
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(per_page)")
        ]
        
        guard let url = URLRequest.makeHTTPRequest(path: "/photos?",
                                                   httpMethod: "GET",
                                                   queryItems: queryItems,
                                                   baseURL: "\(DefaultBaseURL)") else {
            assertionFailure("url dead")
            return nil
        }
        return url
    }
    
    func fetchPhotosNextPage() {
        if let task = task, task.state == .running {
            return
        }
        let nextPage = (lastLoadedPage ?? 0) + 1
        guard let request = makeImagesListRequest(page: nextPage) else {
            assertionFailure("ошибка создания запроса")
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let photoResults):
                    let newPhotos = photoResults.map {
                        Photo($0, date: self.dateFormatter)
                    }
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    NotificationCenter.default.post(
                        name: .didChangeNotification,
                        object: self,
                        userInfo: ["Array": newPhotos]
                    )
                case .failure(let error):
                    assertionFailure("\(error)")
                }
            }
        }
        task.resume()
    }
    
    func changeLike(photoId: String, isLike: Bool, _ complition: @escaping (Result<Void, Error>) -> Void) {
        
        guard let request = makeLikeRequest(photoId: photoId, isLike: isLike) else {
            print("[changeLike]: Запрос статуса лайка не удался")
            return
        }
        
        let task = urlSession.objectTask(for: request) { (result: Result<PhotoLike, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        let photo = self.photos[index]
                        let newPhotoResult = PhotoResult(id: photo.id,
                                                         width: Int(photo.size.width),
                                                         height: Int(photo.size.height),
                                                         createdAt: photo.createdAt?.description,
                                                         description: photo.welcomeDescription,
                                                         urls: UrlsResult(full: photo.largeImageURL,
                                                                          regular: photo.regularImageURL,
                                                                          small: photo.smallImageURL,
                                                                          thumb: photo.thumbImageURL),
                                                         likedByUser: !photo.isLiked)
                        let newPhoto = Photo(newPhotoResult, date: self.dateFormatter)
                        self.photos[index] = newPhoto
                        complition(.success(()))
                    }
                    
                case .failure(let error):
                    fatalError("error like: \(error)")
                }
            }
        }
        task.resume()
    }
    private func makeLikeRequest(photoId: String, isLike: Bool) -> URLRequest? {
        URLRequest.makeHTTPRequest(path: "/photos/\(photoId)/like",
                                   httpMethod: isLike ? "POST" : "DELETE",
                                   baseURL: String(describing: DefaultBaseURL))
    }
}

extension Notification.Name {
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
}
