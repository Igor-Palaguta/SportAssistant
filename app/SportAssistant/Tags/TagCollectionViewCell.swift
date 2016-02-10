import UIKit
import iOSEngine

final class TagCollectionViewCell: UICollectionViewCell, ReusableNibView {
   @IBOutlet private weak var tagLabel: UILabel!

   var trainingTag: Tag! {
      didSet {
         self.tagLabel.text = self.trainingTag.name
      }
   }
}
