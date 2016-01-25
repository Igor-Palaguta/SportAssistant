import UIKit

extension UIAlertController {
   class func presentInController(controller: UIViewController, title: String?, message: String) {
      let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
      alert.addAction(UIAlertAction(title: tr(.OK), style: .Cancel, handler: nil))
      controller.presentViewController(alert, animated: true, completion: nil)
   }
}

extension NSError {
   func presentInController(controller: UIViewController, title: String? = nil) {
      UIAlertController.presentInController(controller, title: title, message: self.localizedDescription)
   }
}
