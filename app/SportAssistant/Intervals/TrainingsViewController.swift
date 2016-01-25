import UIKit
import ReactiveCocoa
import RealmSwift
import iOSEngine

extension TagsFilter {
   var name: String? {
      switch self {
      case All:
         return tr(.AllTrainings)
      case .Selected(let tags):
         return tags.map { $0.name }.joinWithSeparator(", ")
      }
   }

   var trainingsCollection: TrainingsCollection? {
      switch self {
      case All:
         return StorageController.UIController.allTrainings
      case .Selected(let tags):
         return tags.first
      }
   }
}

final class TrainingsViewController: UITableViewController {

   @IBOutlet weak private var bestLabel: UILabel!

   var filter = TagsFilter.All {
      didSet {
         if self.isViewLoaded() {
            self.title = self.filter.name
            self.trainingsCollection = self.filter.trainingsCollection!
            self.tableView.reloadData()
         }
      }
   }

   private var trainings: Results<Training>!

   private dynamic var trainingsCollection: TrainingsCollection! {
      didSet {

         self.trainings = self.trainingsCollection.trainingsOrderedBy(.Date, ascending: false)

         let invalidatedSignal = DynamicProperty(object: trainingsCollection, keyPath: "invalidated")
            .producer
            .map { $0 as! Bool }
            .filter { $0 }
            .map { _ in () }

         let changeSignal = DynamicProperty(object: self, keyPath: "trainingsCollection")
            .producer
            .map { $0 as! TrainingsCollection }
            .skip(1)
            .skipRepeats()
            .map { _ in () }

         let deallocSignal = self.rac_willDeallocSignalProducer()
            .map { _ in () }

         let stopSignal = SignalProducer(values: [invalidatedSignal, changeSignal, deallocSignal]).flatten(.Merge)

         let integralFont = self.bestLabel.font
         DynamicProperty(object: self.bestLabel, keyPath: "attributedText") <~
            DynamicProperty(object: self.trainingsCollection, keyPath: "best")
               .producer
               .takeUntil(stopSignal)
               .map { $0 as! Double }
               .map {
                  best -> NSAttributedString? in
                  return NSNumberFormatter.attributedStringForAcceleration(best, integralFont: integralFont)
         }

         DynamicProperty(object: self.trainingsCollection, keyPath: "version")
            .producer
            .takeUntil(stopSignal)
            .map { $0 as! Int }
            .skip(1)
            .skipRepeats()
            .startWithNext {
               [weak self] _ in
               if let strongSelf = self {
                  strongSelf.tableView.reloadData()
               }
         }
      }
   }

   override func viewDidLoad() {
      super.viewDidLoad()

      self.title = self.filter.name

      self.tableView.estimatedRowHeight = 100
      self.tableView.rowHeight = UITableViewAutomaticDimension

      self.trainingsCollection = self.filter.trainingsCollection!

      self.tableView.tableFooterView = UIView()
   }

   override func viewWillAppear(animated: Bool) {
      super.viewWillAppear(animated)

      if let invalidated = self.trainingsCollection?.invalidated where invalidated {
         self.filter = TagsFilter.All
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
      cell.training = self.trainings[indexPath.row]
      return cell
   }

   override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {

      let deleteAction = UITableViewRowAction(style: .Destructive, title: tr(.Delete)) {
         _, indexPath in
         let training = self.trainings[indexPath.row]
         StorageController.UIController.deleteTraining(training)
      }

      return [deleteAction]
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      if let navigationController = segue.destinationViewController as? UINavigationController,
         tagsViewController = navigationController.viewControllers.first as? TagsViewController {
            tagsViewController.mode = .Picker(self.filter, .Single, .EmptyNotAllowed)
            tagsViewController.completionHandler = {
               [unowned self] tagsViewController in
               if case .Picker(let filter, _, _) = tagsViewController.mode {
                  self.filter = filter
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
