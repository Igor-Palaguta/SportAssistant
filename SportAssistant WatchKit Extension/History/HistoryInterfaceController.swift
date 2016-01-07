import WatchKit
import Foundation

final class HistoryInterfaceController: WKInterfaceController {

   @IBOutlet private weak var table: WKInterfaceTable!

   private var removedIndex: Int?

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      let intervals = HistoryController.mainThreadController.intervals
      self.table.setNumberOfRows(intervals.count, withRowType: String(TrainingController.self))

      for (index, interval) in intervals.enumerate() {
         let row = self.table.rowControllerAtIndex(index) as! TrainingController
         row.interval = interval
      }
   }

   override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()

      if let removedIndex = self.removedIndex {
         self.table.removeRowsAtIndexes(NSIndexSet(index: removedIndex))
         self.removedIndex = nil
      }
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }

   override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
      let intervals = HistoryController.mainThreadController.intervals
      let selectedInterval = intervals[rowIndex]
      self.presentControllerWithNames([String(IntervalInterfaceController.self), String(ChartInterfaceController.self)], contexts: [[selectedInterval, self], selectedInterval])
   }
}

extension HistoryInterfaceController: IntervalInterfaceControllerDelegate {
   func deleteIntervalInterfaceController(controller: IntervalInterfaceController) {
      let historyController = HistoryController.mainThreadController
      self.removedIndex = historyController.intervals.indexOf(controller.interval)
      historyController.deleteInterval(controller.interval)
      controller.dismissController()
   }
}
