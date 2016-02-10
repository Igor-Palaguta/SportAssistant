import UIKit

final class TagsLayout: UICollectionViewFlowLayout {

   private var layoutWidth: CGFloat = 0

   override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
      if newBounds.width != self.layoutWidth {
         self.layoutWidth = newBounds.width
         return true
      }
      return false
   }

   private func indexPathOfLastItemAtSection(section: Int, startItem: Int, endItem: Int) -> NSIndexPath {

      var lastItemInLineIndexPath = NSIndexPath(forItem: startItem, inSection: section)
      if startItem == endItem {
         return lastItemInLineIndexPath
      }

      let itemAttributes = self.layoutAttributesForItemAtIndexPath(lastItemInLineIndexPath)!

      let step = startItem > endItem ? -1 : 1

      for i in (startItem + step).stride(through: endItem, by: step) {
         let currentIndexPath = NSIndexPath(forItem: i, inSection: section)
         if let attributes = self.layoutAttributesForItemAtIndexPath(currentIndexPath) where attributes.frame.minY == itemAttributes.frame.minY {
            lastItemInLineIndexPath = currentIndexPath
         } else {
            break
         }
      }
      return lastItemInLineIndexPath
   }

   private func indexPathOfFirstItemInLineWithItemAtIndexPath(indexPath: NSIndexPath) -> NSIndexPath {
      return self.indexPathOfLastItemAtSection(indexPath.section, startItem: indexPath.item, endItem: 0)
   }

   private func xPositionForItemAtIndexPath(indexPath: NSIndexPath) -> CGFloat {
      let firstItemInLineIndexPath = self.indexPathOfFirstItemInLineWithItemAtIndexPath(indexPath)
      if indexPath == firstItemInLineIndexPath {
         return 0
      }

      let itemsWidth: [CGFloat] = (firstItemInLineIndexPath.item..<indexPath.item).map {
         let currentIndexPath = NSIndexPath(forItem: $0, inSection: indexPath.section)
         let attributes = self.layoutAttributesForItemAtIndexPath(currentIndexPath)!
         return attributes.frame.size.width
      }

      let lineWidth = itemsWidth.reduce(0, combine: +) + self.minimumInteritemSpacing * CGFloat(itemsWidth.count)

      return lineWidth
   }

   override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
      if let attributesArray = super.layoutAttributesForElementsInRect(rect),
         collectionView = self.collectionView {
         return attributesArray.map {
            //attributes must be copied before change
            let attributes = $0.copy() as! UICollectionViewLayoutAttributes

            if attributes.representedElementKind != nil {
               return attributes
            }

            attributes.frame.origin.x = self.xPositionForItemAtIndexPath(attributes.indexPath)

            let maxWidth = floor(collectionView.frame.width - (self.sectionInset.left + self.sectionInset.right))

            attributes.frame.size.width = min(attributes.frame.size.width, maxWidth)

            return attributes
         }
      }
      return nil
   }
}
