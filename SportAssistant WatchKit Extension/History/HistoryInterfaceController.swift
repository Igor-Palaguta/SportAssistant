import WatchKit
import Foundation
import RealmSwift

private struct Ordering: Equatable {
   let orderBy: OrderBy
   let ascending: Bool
}

private func == (lhs: Ordering, rhs: Ordering) -> Bool {
   return lhs.orderBy == rhs.orderBy && lhs.ascending == rhs.ascending
}

private extension NSUserDefaults {
   var ordering: Ordering? {
      set {
         if let ordering = self.ordering {
            self.setObject(ordering.orderBy.rawValue, forKey: "Ordering.orderBy")
            self.setBool(ordering.ascending, forKey: "Ordering.ascending")
            self.synchronize()
         }
      }
      get {
         if let orderByValue = self.objectForKey("Ordering.orderBy") as? String, orderBy = OrderBy(rawValue: orderByValue) {
            return Ordering(orderBy: orderBy, ascending: self.boolForKey("Ordering.ascending"))
         }
         return nil
      }
   }
}

final class HistoryInterfaceController: WKInterfaceController {

   @IBOutlet private weak var table: WKInterfaceTable!
   @IBOutlet private weak var orderByResultButton: WKInterfaceButton!
   @IBOutlet private weak var orderByDateButton: WKInterfaceButton!
   @IBOutlet private weak var showMoreButton: WKInterfaceButton!

   private var removedIndex: Int?
   private var intervals: Results<Interval>!

   private func applyOrdering(ordering: Ordering) {
      let (activeButton, inactiveButton) = ordering.orderBy == .Date
         ? (self.orderByDateButton, self.orderByResultButton)
         : (self.orderByResultButton, self.orderByDateButton)

      let ascendingString = ordering.ascending ? tr(.Ascending) : tr(.Descending)
      activeButton.setTitle(ascendingString + ordering.orderBy.rawValue)

      let anotherField: OrderBy = ordering.orderBy == .Date ? .Result : .Date
      inactiveButton.setTitle(anotherField.rawValue)

      inactiveButton.setBackgroundColor(nil)
      activeButton.setBackgroundColor(UIColor(named: .Base))
      self.reloadData()
   }

   private var ordering = Ordering(orderBy: .Date, ascending: false) {
      didSet {
         if self.ordering != oldValue {
            NSUserDefaults.standardUserDefaults().ordering = self.ordering
            self.applyOrdering(self.ordering)
         }
      }
   }

   private let pageSize = 5

   private func reloadData() {
      let historyController = HistoryController.mainThreadController
      let intervals = historyController.intervalsOrderedBy(self.ordering.orderBy, ascending: self.ordering.ascending)

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

      if let ordering = NSUserDefaults.standardUserDefaults().ordering {
         self.ordering = ordering
      } else {
         self.applyOrdering(self.ordering)
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
      let selectedInterval = self.intervals[rowIndex]
      self.presentControllerWithNames([String(IntervalInterfaceController.self), String(ChartInterfaceController.self)], contexts: [[selectedInterval, self], selectedInterval])
   }

   @IBAction private func orderByDateAction(button: WKInterfaceButton) {
      let ascending = self.ordering.orderBy == .Date
         ? !self.ordering.ascending
         : false
      self.ordering = Ordering(orderBy: .Date, ascending: ascending)
   }

   @IBAction private func orderByResultAction(button: WKInterfaceButton) {
      let ascending = self.ordering.orderBy == .Result
         ? !self.ordering.ascending
         : false
      self.ordering = Ordering(orderBy: .Result, ascending: ascending)
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
