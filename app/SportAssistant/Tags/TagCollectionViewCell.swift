import UIKit
import iOSEngine

final class TagCollectionViewCell: UICollectionViewCell, ReusableNibView {

   @IBOutlet private weak var tagLabel: UILabel!
   @IBOutlet private weak var colorView: UIView!

   var model: TagViewModel! {
      didSet {
         self.tagLabel.text = self.model.name.value
         self.colorView.backgroundColor = self.model.color.value
      }
   }
}
