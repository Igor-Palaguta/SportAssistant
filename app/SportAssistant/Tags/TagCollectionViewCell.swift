import UIKit
import iOSEngine

final class TagCollectionViewCell: UICollectionViewCell, ReusableNibView {

   @IBOutlet private weak var tagLabel: UILabel!
   @IBOutlet private weak var colorView: BadgeView!

   var model: TagViewModel! {
      didSet {
         self.tagLabel.text = self.model.name.value
         self.colorView.color = self.model.color.value
      }
   }
}
