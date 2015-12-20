import UIKit
import RealmSwift
import ReactiveCocoa

final class IntervalsViewController: UITableViewController {

   @IBOutlet weak private var bestLabel: UILabel!

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

   private lazy var achievements: Achievements = {
      let realm = try! Realm()
      return realm.objects(Achievements.self).first!
   }()

   override func viewDidLoad() {
      super.viewDidLoad()

      DynamicProperty(object: self.bestLabel, keyPath: "text") <~
         DynamicProperty(object: self.achievements, keyPath: "acceleration")
            .producer
            .map {
               let acceleration = $0 as! Double
               return "\(acceleration)"
      }

      NSNotificationCenter.defaultCenter()
         .rac_addObserverForName(DidAddIntervalNotification, object: nil)
         .takeUntil(self.rac_willDeallocSignal())
         .subscribeNext {
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
