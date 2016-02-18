import UIKit
import ReactiveCocoa
import RealmSwift
import iOSEngine

final class TrainingsViewController: UITableViewController {

   var model = TrainingsViewModel()

   @IBOutlet weak private var bestLabel: UILabel!

   private var trainings: [Training] = []

   override func viewDidLoad() {
      super.viewDidLoad()

      self.tableView.estimatedRowHeight = 120
      self.tableView.rowHeight = UITableViewAutomaticDimension

      self.tableView.tableFooterView = UIView()

      let integralFont = self.bestLabel.font
      DynamicProperty(object: self.bestLabel, keyPath: "attributedText") <~
         self.model.best
            .map {
               best -> NSAttributedString? in
               return NSNumberFormatter.attributedStringForAcceleration(best, integralFont: integralFont)
      }

      DynamicProperty(object: self, keyPath: "title") <~ self.model.name.producer.map { $0 }

      self.model.trainings.startWithNext {
         [weak self] trainings in
         if let strongSelf = self where trainings != strongSelf.trainings {
            strongSelf.trainings = Array(trainings)
            strongSelf.tableView.reloadData()
         }
      }
   }

   override func viewWillAppear(animated: Bool) {
      super.viewWillAppear(animated)

      if self.model.filter.value.hasInvalidatedTag {
         self.model.filter.value = self.model.filter.value.filterByRemovingInvalidatedTags()
      } else {
         self.tableView.reloadData()
      }
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
      cell.model = TrainingViewModel(training: self.trainings[indexPath.row])
      return cell
   }

   override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {

      let deleteAction = UITableViewRowAction(style: .Destructive, title: tr(.Delete)) {
         _, indexPath in
         let training = self.trainings[indexPath.row]

         let alert = UIAlertController(title: "",
            message: tr(.DeleteConfirmation),
            preferredStyle: .ActionSheet)

         alert.addAction(UIAlertAction(title: tr(.Delete), style: .Destructive) {
            _ in
            StorageController.UIController.deleteTraining(training)
            })

         alert.addCacelAction(title: tr(.Cancel))

         self.presentViewController(alert, animated: true, completion: nil)
      }

      return [deleteAction]
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      if let navigationController = segue.destinationViewController as? UINavigationController,
         tagsViewController = navigationController.viewControllers.first as? TagsViewController {
            tagsViewController.title = tr(.Filter)
            tagsViewController.editable = false
            tagsViewController.actions = [.SelectAll]
            tagsViewController.mode = .Picker(self.model.filter.value, [.AllowsEmpty, .AllowsMultipleSelection, .SelectAllExclusively])
            tagsViewController.completionHandler = {
               [unowned self] tagsViewController in
               if case .Picker(let filter, _) = tagsViewController.mode {
                  self.model.filter.value = filter
               }
               tagsViewController.dismissViewControllerAnimated(true, completion: nil)
            }
      } else if let trainingViewController = segue.destinationViewController as? TrainingViewController,
         cell = sender as? UITableViewCell,
         index = self.tableView.indexPathForCell(cell) {
            trainingViewController.training = self.trainings[index.row]
      }
   }
}
