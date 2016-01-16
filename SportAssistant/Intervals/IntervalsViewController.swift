import UIKit
import ReactiveCocoa
import RealmSwift

final class IntervalsViewController: UITableViewController {

   @IBOutlet weak private var bestLabel: UILabel!

   private var intervals: Results<Interval> {
      return HistoryController.mainThreadController.intervalsOrderedBy(.Date, ascending: false)
   }

   override func viewDidLoad() {
      super.viewDidLoad()

      let integralFont = self.bestLabel.font
      DynamicProperty(object: self.bestLabel, keyPath: "attributedText") <~
         DynamicProperty(object: HistoryController.mainThreadController, keyPath: "best")
            .producer
            .map { $0 as! Double }
            .map {
               best -> NSAttributedString? in
               return NSNumberFormatter.attributedStringForAcceleration(best, integralFont: integralFont)
      }

      DynamicProperty(object: HistoryController.mainThreadController, keyPath: "version")
         .producer
         .map { $0 as! Int }
         .skip(1)
         .skipRepeats()
         .startWithNext {
            [weak self] _ in
            if let strongSelf = self {
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

   override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {

      let deleteAction = UITableViewRowAction(style: .Destructive, title: tr(.Delete)) {
         _, indexPath in
         let interval = self.intervals[indexPath.row]
         HistoryController.mainThreadController.deleteInterval(interval)
      }

      return [deleteAction];
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      if let intervalViewController = segue.destinationViewController as? IntervalViewController,
      cell = sender as? UITableViewCell,
      index = self.tableView.indexPathForCell(cell) {
         intervalViewController.interval = self.intervals[index.row]
      }
   }
}
