import UIKit
import Kingfisher

public protocol ProfileViewControllerProtocol: AnyObject {
    var presenter: ProfileViewPresenterProtocol? { get set }
    func setupProfileDetails(name: String, login: String, bio: String)
    func setupAvatar(url: URL)
}

final class ProfileViewController: UIViewController, ProfileViewControllerProtocol, AlertPresenterDelegate {
    
    private lazy var avatarPlaceHolder = UIImage(named: "placeholder")
    private let profileService = ProfileService.shared
    
    private lazy var profilePhoto: UIImageView = {
        let image = UIImage(named: "placeholder")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true // Для скругления углов
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Екатерина Новикова"
        label.textColor = .ypWhite
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.accessibilityIdentifier = "nameLabel"
        return label
    }()
    
    private lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.text = "@ekaerina_nov"
        label.textColor = .ypGray
        label.font = UIFont.systemFont(ofSize: 13)
        label.accessibilityIdentifier = "nicknameLabel"
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Hello, world!"
        label.textColor = .ypWhite
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()
    
    var presenter: ProfileViewPresenterProtocol? = {
        return ProfileViewPresenter()
    }()
    
    private lazy var logoutButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "ipad.and.arrow.forward")
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
        button.accessibilityIdentifier = "logout"
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        setupViews()
        setupAllConstraints()
        presenter?.view = self
        presenter?.updateProfileDetails()
        presenter?.observerProfileImageService()
        alertPresenter.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyGradients()
    }
    
    private func applyGradients() {
        
        let profilePhotoColors = [UIColor.ypGray, UIColor.ypWhite]
        let nameLabelColors = [UIColor.ypGray, UIColor.ypWhite]
        let nicknameLabelColors = [UIColor.ypGray, UIColor.ypWhite]
        let descriptionLabelColors = [UIColor.ypGray, UIColor.ypWhite]
        
        profilePhoto.applyGradient(colors: profilePhotoColors, cornerRadius: 35)
        nameLabel.applyGradient(colors: nameLabelColors, cornerRadius: 10)
        nicknameLabel.applyGradient(colors: nicknameLabelColors, cornerRadius: 5)
        descriptionLabel.applyGradient(colors: descriptionLabelColors, cornerRadius: 5)
    }
    
    func setupProfileDetails(name: String, login: String, bio: String) {
        nameLabel.text = name
        nicknameLabel.text = login
        descriptionLabel.text = bio
    }
    
    func setupAvatar(url: URL) {
        let cache = ImageCache.default
        cache.clearDiskCache()
        cache.clearMemoryCache()
        let processor = RoundCornerImageProcessor(cornerRadius: 35) // Половина размера (70/2)
        
        profilePhoto.kf.setImage(with: url, placeholder: avatarPlaceHolder, options: [.processor(processor), .transition(.fade(1))]) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let image):
                self.profilePhoto.image = image.image
                self.removeGradients()
            case .failure(let error):
                print("[setupAvatar]: ошибка настройки аватара \(error)")
            }
        }
    }
    
    private func removeGradients() {
        let viewsToRemoveGradients: [UIView] = [profilePhoto, nameLabel, nicknameLabel, descriptionLabel, logoutButton]
        viewsToRemoveGradients.forEach { $0.removeGradient() }
    }
    
    private func setupViews() {
        [profilePhoto,
         nameLabel,
         nicknameLabel,
         descriptionLabel,
         logoutButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }
    
    private func setupAllConstraints() {
        NSLayoutConstraint.activate([
            profilePhoto.heightAnchor.constraint(equalToConstant: 70),
            profilePhoto.widthAnchor.constraint(equalToConstant: 70),
            profilePhoto.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            profilePhoto.topAnchor.constraint(equalTo: view.topAnchor, constant: 76),
            
            nameLabel.topAnchor.constraint(equalTo: profilePhoto.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), // Для корректного отображения градиента
            
            nicknameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            nicknameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nicknameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), // Для корректного отображения градиента
            
            descriptionLabel.topAnchor.constraint(equalTo: nicknameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            logoutButton.centerYAnchor.constraint(equalTo: profilePhoto.centerYAnchor)
        ])
    }
    
    private lazy var alertPresenter = AlertPresenter()
    
    func sendAlert(alert: UIAlertController) {
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc
    private func didTapLogoutButton() {
        let imagesListCell = ImagesListCell()
        let yesAction = AlertButtonModel(title: "Да", style: .default) { _ in
            OAuth2TokenStorage.shared.clean()
            WebViewViewController.clean()
            imagesListCell.clean()
            
            guard let window = UIApplication.shared.windows.first else {
                fatalError("invalid configuration")
            }
            window.rootViewController = SplashViewController()
            window.makeKeyAndVisible()
        }
        let noAction = AlertButtonModel(title: "Нет", style: .default) { _ in
            self.dismiss(animated: true)
        }
        
        let alert = AlertModel(title: "Пока, пока!",
                               message: "Уверены что хотите выйти?",
                               preferredStyle: .alert,
                               primaryButton: yesAction,
                               secondaryButton: noAction)
        
        alertPresenter.alertPresent(alertModel: alert)
    }
}

// MARK: Update Profile Details
private extension ProfileViewController {
    func updateProfileDetails() {
        guard let profile = profileService.profile else { return }
        nameLabel.text = "\(profile.firstName) \(profile.lastName ?? "")"
        nicknameLabel.text = "@\(profile.username)"
        descriptionLabel.text = profile.bio
    }
}

// MARK: - Status Bar Style
extension ProfileViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

// MARK: - Profile Gradient Style
extension UIView {
    
    func applyGradient(
        colors: [UIColor],
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1),
        cornerRadius: CGFloat = 0
    ) {
        self.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        
        let gradient = CAGradientLayer()
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        gradient.cornerRadius = cornerRadius
        gradient.frame = self.bounds
        
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    func removeGradient() {
        self.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
    }
}
