import WatchKit
import Foundation
import RealmSwift
import watchOSEngine

private struct Ordering: Equatable {
   let orderBy: OrderBy
   let ascending: Bool

   func reversedOrdering() -> Ordering {
      return Ordering(orderBy: self.orderBy, ascending: !self.ascending)
   }
}

private func == (lhs: Ordering, rhs: Ordering) -> Bool {
   return lhs.orderBy == rhs.orderBy && lhs.ascending == rhs.ascending
}

private extension NSUserDefaults {
   var ordering: Ordering? {
      set {
         if let ordering = newValue {
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
   private var trainings: Results<Training>!

   private var ordering: Ordering! {
      didSet {
         if self.ordering != oldValue {
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
      }
   }

   private let pageSize = 5

   private func reloadData() {
      let storage = StorageController.UIController
      let trainings = storage.trainingsOrderedBy(self.ordering.orderBy, ascending: self.ordering.ascending)

      let currentPageSize = min(trainings.count, self.pageSize)
      self.table.setNumberOfRows(currentPageSize, withRowType: String(TrainingController.self))

      (0..<currentPageSize).forEach {
         index in
         let row = self.table.rowControllerAtIndex(index) as! TrainingController
         row.training = trainings[index]
      }

      self.showMoreButton.setHidden(currentPageSize == trainings.count)

      self.trainings = trainings
   }

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      if let ordering = NSUserDefaults.standardUserDefaults().ordering {
         self.ordering = ordering
      } else {
         self.ordering = Ordering(orderBy: .Date, ascending: false)
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
      let selectedTraining = self.trainings[rowIndex]
      self.presentControllerWithNames([String(TrainingInterfaceController.self), String(ChartInterfaceController.self)], contexts: [[selectedTraining, self], selectedTraining])
   }

   private func selectOrderBy(orderBy: OrderBy) {
      self.ordering = self.ordering.orderBy == orderBy
         ? self.ordering.reversedOrdering()
         : Ordering(orderBy: orderBy, ascending: false)
      NSUserDefaults.standardUserDefaults().ordering = self.ordering
   }

   @IBAction private func orderByDateAction(button: WKInterfaceButton) {
      self.selectOrderBy(.Date)
   }

   @IBAction private func orderByResultAction(button: WKInterfaceButton) {
      self.selectOrderBy(.Result)
   }

   @IBAction private func showMoreAction(button: WKInterfaceButton) {
      let startIndex = self.table.numberOfRows
      let currentPageSize = min(self.pageSize, self.trainings.count - startIndex)
      if currentPageSize >= 0 {
         let pageIndexes = NSIndexSet(indexesInRange: NSRange(location: startIndex, length: currentPageSize))
         self.table.insertRowsAtIndexes(pageIndexes, withRowType: String(TrainingController.self))
         pageIndexes.forEach {
            index in
            let row = self.table.rowControllerAtIndex(index) as! TrainingController
            row.training = self.trainings[index]
         }
      }

      self.showMoreButton.setHidden(currentPageSize < self.pageSize)
   }
}

extension HistoryInterfaceController: TrainingInterfaceControllerDelegate {
   func deleteTrainingInterfaceController(controller: TrainingInterfaceController) {
      let storage = StorageController.UIController
      self.removedIndex = self.trainings!.indexOf(controller.training)
      storage.deleteTraining(controller.training)
      controller.dismissController()
   }
}
