import UIKit
import RealmSwift
import ReactiveCocoa

final class IntervalsViewController: UITableViewController {

   @IBOutlet weak private var bestLabel: UILabel!

   private var _intervals: List<Interval>?

   private var intervals: List<Interval> {
      if let intervals = self._intervals {
         return intervals
      }
      let intervals = self.history.intervals
      self._intervals = intervals
      return intervals
   }

   private lazy var history: History = {
      let realm = try! Realm()
      return realm.currentHistory
   }()

   override func viewDidLoad() {
      super.viewDidLoad()

      DynamicProperty(object: self.bestLabel, keyPath: "text") <~
         DynamicProperty(object: self.history, keyPath: "best")
            .producer
            .map {
               let best = $0 as! Double
               return NSNumberFormatter.formatAccelereration(best)
      }

      DynamicProperty(object: self.history, keyPath: "intervalsCount")
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
