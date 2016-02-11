import UIKit

final class ColorCell: UICollectionViewCell, ReusableNibView {

   @IBOutlet private weak var colorView: UIView!

   var color = UIColor.clearColor() {
      didSet {
         self.colorView.backgroundColor = self.color
      }
   }

   override func awakeFromNib() {
      super.awakeFromNib()

      self.colorView.layer.borderWidth = 2
      self.colorView.layer.borderColor = UIColor.clearColor().CGColor
   }

   override var selected: Bool {
      didSet {
         self.colorView.layer.borderColor = selected
            ? UIColor.blackColor().CGColor
            : UIColor.clearColor().CGColor
      }
   }
}
