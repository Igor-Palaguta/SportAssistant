import WatchKit
import Foundation

class TrainingsInterfaceController: WKInterfaceController {

   @IBOutlet weak var table: WKInterfaceTable!

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      self.table.setNumberOfRows(Archive.sharedArchive.count, withRowType: String(TrainingController.self))

      for (index, training) in Archive.sharedArchive.trainings.enumerate() {
         let row = self.table.rowControllerAtIndex(index) as! TrainingController
         row.training = training
      }
   }

   override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }
}
