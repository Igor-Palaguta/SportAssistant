import UIKit
import ReactiveCocoa
import RealmSwift

final class IntervalsViewController: UITableViewController {

   @IBOutlet weak private var bestLabel: UILabel!

   private var _intervals: List<Interval>?

   private var intervals: List<Interval> {
      if let intervals = self._intervals {
         return intervals
      }
      let intervals = self.historyController.intervals
      self._intervals = intervals
      return intervals
   }

   private lazy var historyController = HistoryController()

   override func viewDidLoad() {
      super.viewDidLoad()

      let integralFont = self.bestLabel.font
      DynamicProperty(object: self.bestLabel, keyPath: "attributedText") <~
         DynamicProperty(object: self.historyController, keyPath: "best")
            .producer
            .map { $0 as! Double }
            .map {
               best -> NSAttributedString? in
               return NSNumberFormatter.attributedStringForAcceleration(best, integralFont: integralFont)
      }

      DynamicProperty(object: self.historyController, keyPath: "intervalsCount")
         .producer
         .map { $0 as! Int }
         .skip(1)
         .skipRepeats()
         .startWithNext {
            [weak self] _ in
            if let strongSelf = self {
               strongSelf._intervals = nil
               strongSelf.tableView.reloadData()
            }
      }

      self.tableView.tableFooterView = UIView()
   }

   override func shouldAutorotate() -> Bool {
      return true
   }

   override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
      return [.Portrait]
   }

   override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.intervals.count
   }

   override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
      let cell: IntervalCell = tableView.dequeueCellForIndexPath(indexPath)
      cell.interval = self.intervals[indexPath.row]
      return cell
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      if let intervalViewController = segue.destinationViewController as? IntervalViewController,
      cell = sender as? UITableViewCell,
      index = self.tableView.indexPathForCell(cell) {
         intervalViewController.interval = self.intervals[index.row]
      }
   }
}
