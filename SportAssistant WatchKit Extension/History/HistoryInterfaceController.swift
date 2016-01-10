import WatchKit
import Foundation
import RealmSwift

final class HistoryInterfaceController: WKInterfaceController {

   @IBOutlet private weak var table: WKInterfaceTable!
   @IBOutlet private weak var orderByResultButton: WKInterfaceButton!
   @IBOutlet private weak var orderByDateButton: WKInterfaceButton!

   private var removedIndex: Int?
   private var intervals: Results<Interval>?

   private enum OrderBy: Int {
      case Date
      case Result
   }

   private var orderBy: OrderBy? {
      didSet {
         guard let orderBy = self.orderBy where orderBy != oldValue else {
            return
         }

         NSUserDefaults.standardUserDefaults().setInteger(orderBy.rawValue, forKey: "orderBy")
         NSUserDefaults.standardUserDefaults().synchronize()

         let (activeButton, inactiveButton) = orderBy == .Date
            ? (self.orderByDateButton, self.orderByResultButton)
            : (self.orderByResultButton, self.orderByDateButton)

         inactiveButton.setBackgroundColor(nil)
         activeButton.setBackgroundColor(UIColor(named: .Base))
         self.reloadData()
      }
   }

   private func reloadData() {
      guard let orderBy = self.orderBy else {
         return
      }

      let historyController = HistoryController.mainThreadController
      let intervals = orderBy == .Date ? historyController.intervals : historyController.bestIntervals

      self.table.setNumberOfRows(intervals.count, withRowType: String(TrainingController.self))

      for (index, interval) in intervals.enumerate() {
         let row = self.table.rowControllerAtIndex(index) as! TrainingController
         row.interval = interval
      }

      self.intervals = intervals
   }

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      let orderBy = OrderBy(rawValue: NSUserDefaults.standardUserDefaults().integerForKey("orderBy"))!
      self.orderBy = orderBy
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
      let selectedInterval = self.intervals![rowIndex]
      self.presentControllerWithNames([String(IntervalInterfaceController.self), String(ChartInterfaceController.self)], contexts: [[selectedInterval, self], selectedInterval])
   }

   @IBAction private func orderByDateAction(button: WKInterfaceButton) {
      self.orderBy = .Date
   }

   @IBAction private func orderByResultAction(button: WKInterfaceButton) {
      self.orderBy = .Result
   }
}

extension HistoryInterfaceController: IntervalInterfaceControllerDelegate {
   func deleteIntervalInterfaceController(controller: IntervalInterfaceController) {
      let historyController = HistoryController.mainThreadController
      self.removedIndex = self.intervals!.indexOf(controller.interval)
      historyController.deleteInterval(controller.interval)
      controller.dismissController()
   }
}
