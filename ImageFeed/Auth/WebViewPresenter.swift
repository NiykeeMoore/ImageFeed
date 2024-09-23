import Foundation

public protocol WebViewPresenterProtocol {
    var view: WebViewViewControllerProtocol? { get set }
    func viewDidLoad()
    func didUpdateProgressValue(_ newValue: Double)
    func code(from url: URL) -> String?
}

final class WebViewPresenter: WebViewPresenterProtocol {
    
    private let authHelper: AuthHelperProtocol
    weak var view: WebViewViewControllerProtocol?
    
    init(authHelper: AuthHelperProtocol) {
        self.authHelper = authHelper
    }
    
    func code(from url: URL) -> String? {
        return authHelper.code(from: url)
    }
    
    func didUpdateProgressValue(_ newValue: Double) {
        let newProgressValue = Float(newValue)
        view?.setProgressValue(newProgressValue)
        
        let shouldHideProgress = shouldHideProgress(for: newProgressValue)
        view?.setProgressHidden(shouldHideProgress)
    }
    
    func shouldHideProgress(for value: Float) -> Bool {
        return abs(value - 1.0) <= 0.0001
    }
    
    func viewDidLoad() {
        let request = authHelper.authRequest()
        view?.load(request: request)
        didUpdateProgressValue(0)
    }
}
