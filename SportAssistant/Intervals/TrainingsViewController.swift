import UIKit
import ReactiveCocoa
import RealmSwift

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
         return StorageController.UIController.history
      case .Selected(let tags):
         return tags.first
      }
   }
}

final class TrainingsViewController: UITableViewController {

   @IBOutlet weak private var bestLabel: UILabel!

   var filter = TagsFilter.All {
      didSet {
         self.title = self.filter.name
         self.trainingsCollection = self.filter.trainingsCollection!
         self.trainings = self.trainingsCollection.trainingsOrderedBy(.Date, ascending: false)
         self.tableView.reloadData()
      }
   }

   private lazy var trainings: Results<Training> = {
      return self.trainingsCollection.trainingsOrderedBy(.Date, ascending: false)
   }()

   private dynamic lazy var trainingsCollection: TrainingsCollection = {
      return self.filter.trainingsCollection!
   }()

   override func viewDidLoad() {
      super.viewDidLoad()

      self.title = self.filter.name

      let integralFont = self.bestLabel.font
      DynamicProperty(object: self.bestLabel, keyPath: "attributedText") <~
         DynamicProperty(object: self, keyPath: "trainingsCollection.best")
            .producer
            .ignoreNil()
            .map { $0 as! Double }
            .map {
               best -> NSAttributedString? in
               return NSNumberFormatter.attributedStringForAcceleration(best, integralFont: integralFont)
      }

      DynamicProperty(object: self, keyPath: "trainingsCollection.version")
         .producer
         .ignoreNil()
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
