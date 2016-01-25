import WatchKit
import Foundation
import HealthKit
import RealmSwift

final class TagsInterfaceController: WKInterfaceController {

   @IBOutlet private weak var table: WKInterfaceTable!

   private var healthStore: HKHealthStore!

   private var tags: [Tag]!

   private func reloadData() {
      self.tags = Array(StorageController.UIController.recentTags)

      self.table.setNumberOfRows(self.tags.count + 1, withRowType: String(TagController.self))

      for (index, tag) in self.tags.enumerate() {
         let row = self.table.rowControllerAtIndex(index) as! TagController
         row.trainingTag = tag
      }
      let otherRow = self.table.rowControllerAtIndex(self.tags.count) as! TagController
      otherRow.nameLabel.setText(tr(.Other))
      otherRow.dateLabel.setText(nil)
      otherRow.bestLabel.setText(nil)
   }

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      self.healthStore = context as! HKHealthStore
   }

   override func didAppear() {
      super.didAppear()

      self.reloadData()
   }

   override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }

   override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
      if segueIdentifier == String(RecordTrainingInterfaceController.self) {
         let tag: Tag? = rowIndex < self.tags.count ? self.tags[rowIndex] : nil
         return TrainingContext(healthStore: self.healthStore, tag: tag)
      }
      return nil
   }

}
