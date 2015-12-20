import UIKit
import RealmSwift

class IntervalsViewController: UITableViewController {

   private var _intervals: Results<Interval>?

   private var intervals: Results<Interval> {
      if let intervals = self._intervals {
         return intervals
      }
      let realm = try! Realm()
      let intervals = realm.objects(Interval).sorted("start", ascending: false)
      self._intervals = intervals
      return intervals
   }

   override func viewDidLoad() {
      super.viewDidLoad()

      NSNotificationCenter.defaultCenter().addObserver(self,
         selector: Selector("reloadData"),
         name: DidAddIntervalNotification,
         object: nil)
   }

   @objc private func reloadData() {
      self._intervals = nil
      self.tableView.reloadData()
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
