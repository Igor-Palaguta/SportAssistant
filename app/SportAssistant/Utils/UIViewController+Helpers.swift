import UIKit

extension UIViewController {
   func dismissAction(_: UIBarButtonItem) {
      self.dismissViewControllerAnimated(true, completion: nil)
   }
}
