import UIKit
import Kingfisher

protocol ImagesListDelegate: AnyObject {
    func imagesListCellDidTapLike(_ cell: ImagesListCell)
}

public final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    private let cache = ImageCache.default
    weak var delegate: ImagesListDelegate?
    @IBOutlet private weak var likeButton: UIButton!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var imageCell: UIImageView!
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    public override func prepareForReuse() {
        imageCell.kf.cancelDownloadTask()
    }
    
    func setupCell(from photo: Photo) {
        cache.clearMemoryCache()
        cache.clearDiskCache()
        
        let url = URL(string: photo.smallImageURL)
        imageCell.kf.indicatorType = .activity
        imageCell.kf.setImage(with: url, placeholder: UIImage(named: "ImagePlaceholder")) { result in
            switch result {
            case .success(let image):
                self.imageCell.contentMode = .scaleAspectFill
                self.imageCell.image = image.image
            case .failure(let error):
                print("[setupCell]: Ошибка загрузки картинки: \(error)")
                self.imageCell.image = UIImage(named: "ImagePlaceholder")
            }
        }
        dateLabel.text = dateFormatter.string(from: photo.createdAt ?? Date())
        setIsLiked(isLiked: photo.isLiked)
    }
    
    func setIsLiked(isLiked: Bool) {
        let likeImage = isLiked ? UIImage(named: "likeOn") : UIImage(named: "likeOff")
        likeButton.setImage(likeImage, for: .normal)
    }
    
    func clean() {
        let cache = ImageCache.default
        cache.clearMemoryCache()
        cache.clearDiskCache()
        cache.backgroundCleanExpiredDiskCache()
        cache.cleanExpiredMemoryCache()
        cache.clearCache()
    }
    
    @IBAction private func likeButtonClicked(_ sender: UIButton) {
        delegate?.imagesListCellDidTapLike(self)
    }
}
