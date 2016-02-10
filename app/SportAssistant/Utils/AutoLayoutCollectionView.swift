import UIKit

final class AutoLayoutCollectionView: UICollectionView {
   override func intrinsicContentSize() -> CGSize {
      return (self.collectionViewLayout as! UICollectionViewFlowLayout).collectionViewContentSize()
   }
}
