import UIKit

extension UINavigationController {
   public override func shouldAutorotate() -> Bool {
      return true
   }

   public override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
      return .Portrait
   }

   public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
      if let viewController = self.viewControllers.last {
         return viewController.supportedInterfaceOrientations()
      }
      return .Portrait
   }
}

extension UITabBarController {

   public override func shouldAutorotate() -> Bool {
      return self.selectedViewController?.shouldAutorotate() ?? true
   }

   public override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
      return self.selectedViewController?.preferredInterfaceOrientationForPresentation() ?? .Portrait
   }

   public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
      return self.selectedViewController?.supportedInterfaceOrientations() ?? .Portrait
   }
}
