import Foundation

protocol ImagesListServiceProtocol {
    var photos: [Photo] { get }
    func fetchPhotosNextPage()
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void)
}

final class ImagesListService: ImagesListServiceProtocol {
    
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private let urlSession = URLSession.shared
    private var currentTask: URLSessionTask?
    private let dateFormatter = ISO8601DateFormatter()
    
    private init() {}
    
    // MARK: Response Photo Next Page
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)
        guard currentTask == nil else { return }
        let nextPage = (lastLoadedPage ?? 0) + 1
        guard let request = makeRequest(page: nextPage) else {
            print("Ошибка создания запроса")
            return
        }
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let photoResults):
                    if self.lastLoadedPage == nil {
                        self.lastLoadedPage = 1
                    } else {
                        self.lastLoadedPage! += 1
                    }
                    let newPhotos = photoResults.map { Photo($0, date: self.dateFormatter) }
                    self.photos.append(contentsOf: newPhotos)
                    NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            self.currentTask = nil
        }
        self.currentTask = task
        task.resume()
    }
    
    // MARK: Response Change Like
    func changeLike(photoId: String, isLike: Bool, _ complition: @escaping (Result<Void, Error>) -> Void) {
        if currentTask != nil {
            currentTask?.cancel()
        }
        
        guard let request = makeLikeRequest(photoId: photoId, isLike: isLike) else {
            print("[changeLike]: Ошибка получения статуса лайка")
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
        self.currentTask = task
        task.resume()
    }
    
    // MARK: Requests
    private func makeRequest(page: Int) -> URLRequest? {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "10")
        ]
        return URLRequest.makeHTTPRequest(path: "/photos",
                                          httpMethod: "GET",
                                          queryItems: queryItems,
                                          baseURL: String(describing: Constants.defaultBaseURL))
    }
    
    private func makeLikeRequest(photoId: String, isLike: Bool) -> URLRequest? {
        URLRequest.makeHTTPRequest(path: "/photos/\(photoId)/like",
                                   httpMethod: isLike ? "POST" : "DELETE",
                                   baseURL: String(describing: Constants.defaultBaseURL))
    }
}
