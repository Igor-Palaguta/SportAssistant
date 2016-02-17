import Foundation
import UIKit

final class Theme {
   func apply() {
      UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont(userFont: .Regular(.None), size: 18)]

      UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(userFont: .Regular(.None), size: 12)],
         forState: .Normal)

      let buttonAppearance = UIBarButtonItem.appearanceWhenContainedInInstancesOfClasses([UINavigationBar.self])

      buttonAppearance.setTitleTextAttributes([NSFontAttributeName: UIFont(userFont: .Regular(.None), size: 15)],
         forState: .Normal)
   }
}
