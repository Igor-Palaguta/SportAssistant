import UIKit
import ReactiveCocoa
import RealmSwift

final class TrainingsViewController: UITableViewController {

   @IBOutlet weak private var bestLabel: UILabel!

   private var trainings: Results<Training> {
      return HistoryController.mainThreadController.trainingsOrderedBy(.Date, ascending: false)
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
         .takeUntil(self.rac_willDeallocSignal().toVoidNoErrorSignalProducer())
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
      return self.trainings.count
   }

   override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
      let cell: TrainingCell = tableView.dequeueCellForIndexPath(indexPath)
      cell.training = self.trainings[indexPath.row]
      return cell
   }

   override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {

      let deleteAction = UITableViewRowAction(style: .Destructive, title: tr(.Delete)) {
         _, indexPath in
         let training = self.trainings[indexPath.row]
         HistoryController.mainThreadController.deleteTraining(training)
      }

      return [deleteAction];
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      if let trainingViewController = segue.destinationViewController as? TrainingViewController,
      cell = sender as? UITableViewCell,
      index = self.tableView.indexPathForCell(cell) {
         trainingViewController.training = self.trainings[index.row]
      }
   }
}
