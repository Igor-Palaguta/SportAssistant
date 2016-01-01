import WatchKit
import Foundation

class HistoryInterfaceController: WKInterfaceController {

   @IBOutlet weak var table: WKInterfaceTable!

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      let historyController = HistoryController()

      let intervals = historyController.intervals
      self.table.setNumberOfRows(intervals.count, withRowType: String(TrainingController.self))

      for (index, interval) in intervals.enumerate() {
         let row = self.table.rowControllerAtIndex(index) as! TrainingController
         row.interval = interval
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
