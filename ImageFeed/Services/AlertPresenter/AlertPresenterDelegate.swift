import UIKit

protocol AlertPresenterDelegate: AnyObject {
    func sendAlert(alert: UIAlertController)
}
