import UIKit

final class ColorCell: UICollectionViewCell, ReusableNibView {

   @IBOutlet private weak var colorView: UIView!

   var color = UIColor.clearColor() {
      didSet {
         self.colorView.backgroundColor = self.color
         self.selectedBackgroundView?.backgroundColor = self.color.colorWithAlphaComponent(0.3)
      }
   }
}
