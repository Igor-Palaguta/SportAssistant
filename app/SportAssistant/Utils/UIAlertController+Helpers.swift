import UIKit

extension UIAlertController {
   func addCacelAction(title title: String = tr(.Cancel)) {
      self.addAction(UIAlertAction(title: title, style: .Cancel, handler: nil))
   }

   class func presentInController(controller: UIViewController, title: String?, message: String) {
      let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
      alert.addCacelAction(title: tr(.OK))
      controller.presentViewController(alert, animated: true, completion: nil)
   }
}

extension NSError {
   func presentInController(controller: UIViewController, title: String? = nil) {
      UIAlertController.presentInController(controller, title: title, message: self.localizedDescription)
   }
}
