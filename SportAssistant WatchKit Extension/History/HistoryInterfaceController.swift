import WatchKit
import Foundation
import RealmSwift

final class HistoryInterfaceController: WKInterfaceController {

   @IBOutlet private weak var table: WKInterfaceTable!
   @IBOutlet private weak var orderByResultButton: WKInterfaceButton!
   @IBOutlet private weak var orderByDateButton: WKInterfaceButton!
   @IBOutlet private weak var showMoreButton: WKInterfaceButton!

   private var removedIndex: Int?
   private var intervals: Results<Interval>!

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

   private let pageSize = 5

   private func reloadData() {
      guard let orderBy = self.orderBy else {
         return
      }

      let historyController = HistoryController.mainThreadController
      let intervals = orderBy == .Date ? historyController.intervals : historyController.bestIntervals

      let currentPageSize = min(intervals.count, self.pageSize)
      self.table.setNumberOfRows(currentPageSize, withRowType: String(TrainingController.self))

      (0..<currentPageSize).forEach {
         index in
         let row = self.table.rowControllerAtIndex(index) as! TrainingController
         row.interval = intervals[index]
      }

      self.showMoreButton.setHidden(currentPageSize == intervals.count)

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
      let selectedInterval = self.intervals[rowIndex]
      self.presentControllerWithNames([String(IntervalInterfaceController.self), String(ChartInterfaceController.self)], contexts: [[selectedInterval, self], selectedInterval])
   }

   @IBAction private func orderByDateAction(button: WKInterfaceButton) {
      self.orderBy = .Date
   }

   @IBAction private func orderByResultAction(button: WKInterfaceButton) {
      self.orderBy = .Result
   }

   @IBAction private func showMoreAction(button: WKInterfaceButton) {
      let startIndex = self.table.numberOfRows
      let currentPageSize = min(self.pageSize, self.intervals.count - startIndex)
      if currentPageSize >= 0 {
         let pageIndexes = NSIndexSet(indexesInRange: NSRange(location: startIndex, length: currentPageSize))
         self.table.insertRowsAtIndexes(pageIndexes, withRowType: String(TrainingController.self))
         pageIndexes.forEach {
            index in
            let row = self.table.rowControllerAtIndex(index) as! TrainingController
            row.interval = self.intervals[index]
         }
      }

      self.showMoreButton.setHidden(currentPageSize < self.pageSize)
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
