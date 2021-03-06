import UIKit
import HealthKit
import ReactiveCocoa
import iOSEngine

private enum TagSection: Int {
   case Information
   case Delete
   case SectionCount
}

protocol TagViewControllerDelegate: class {
   func didCompleteTagViewController(controller: TagViewController)
   func tagViewController(controller: TagViewController, didAddTag tag: Tag)
   func tagViewController(controller: TagViewController, didEditTag tag: Tag)
}

final class TagViewController: UITableViewController {

   var model: EditableTagViewModel = AddTagViewModel()
   weak var delegate: TagViewControllerDelegate?

   @IBOutlet private weak var nameField: UITextField!
   @IBOutlet private weak var activityLabel: UILabel!
   @IBOutlet private weak var countLabel: UILabel!
   @IBOutlet private weak var colorsView: UICollectionView!

   private lazy var colors: [UIColor] = [UIColor(named: .Asbestos),
      UIColor(named: .BelizeHole),
      UIColor(named: .GreenSea),
      UIColor(named: .MidnightBlue),
      UIColor(named: .Nephritis),
      UIColor(named: .Orange),
      UIColor(named: .Pomegranate),
      UIColor(named: .Pumpkin),
      UIColor(named: .Wisteria)]

   private lazy var saveAction: CocoaAction = {
      return CocoaAction(self.model.saveAction, input: self.model)
   }()

   override func viewDidLoad() {
      super.viewDidLoad()

      self.title = self.model.title
      self.nameField.text = self.model.name.value

      self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
         target: self,
         action: Selector("cancelAction:"))

      self.model.isDefaultName <~ self.nameField.rac_signalForControlEvents(.EditingChanged)
         .toVoidNoErrorSignalProducer()
         .map { [weak textField = self.nameField] _ in textField?.text ?? "" }
         .map { $0.isEmpty }

      self.model.name <~ self.nameField.rac_textSignal()
         .toNoErrorSignalProducer()
         .map { $0 as? String ?? "" }

      DynamicProperty(object: self.activityLabel, keyPath: "text") <~
         self.model.activityType
            .producer
            .map { $0.name }

      DynamicProperty(object: self.countLabel, keyPath: "text") <~
         self.model.trainingsCount
            .producer
            .map { tr(.TrainingsCountFormat($0)) }

      DynamicProperty(object: self.countLabel, keyPath: "hidden") <~
         self.model.hasTrainings
            .producer
            .map { !$0 }

      self.model.activityType.producer
         .skipRepeats()
         .startWithNext {
            [weak self] type in
            guard let strongSelf = self where strongSelf.model.isDefaultName.value else {
               return
            }

            let suggestedName = type == .Other ? "" : type.name
            strongSelf.model.name.value = suggestedName
            strongSelf.nameField.text = suggestedName
      }

      self.model.hasTrainings
         .producer
         .skip(1)
         .skipRepeats()
         .startWithNext {
            [weak self] _ in
            self?.tableView.reloadData()
      }

      self.model.saveAction.values.observeNext {
         [weak self] (let tag, let isNew) in
         guard let strongSelf = self else {
            return
         }

         if isNew {
            strongSelf.delegate?.tagViewController(strongSelf, didAddTag: tag)
         } else {
            strongSelf.delegate?.tagViewController(strongSelf, didEditTag: tag)
         }
      }

      let saveItem = UIBarButtonItem(barButtonSystemItem: .Done,
         target: self.saveAction,
         action: CocoaAction.selector)

      DynamicProperty(object: saveItem, keyPath: "enabled") <~
         self.model.name
            .producer
            .map { !$0.isEmpty }

      self.navigationItem.rightBarButtonItem = saveItem
   }

   override func viewDidAppear(animated: Bool) {
      super.viewDidAppear(animated)

      if let index = self.colors.indexOf(self.model.color.value) {
         self.colorsView.selectItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0),
            animated: true,
            scrollPosition: .CenteredHorizontally)
      }
   }

   override func shouldAutorotate() -> Bool {
      return true
   }

   override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
      return [.Portrait]
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      if let activitiesViewController = segue.destinationViewController as? ActivitiesViewController {
         activitiesViewController.activityType = self.model.activityType.value
      }
   }

   @IBAction private func unwindActivitySegue(segue: UIStoryboardSegue) {
      if let activitiesViewController = segue.sourceViewController as? ActivitiesViewController {
         self.model.activityType.value = activitiesViewController.activityType
      }
   }

   @IBAction private func cancelAction(_: UIBarButtonItem) {
      self.delegate!.didCompleteTagViewController(self)
   }

   @IBAction private func deleteAction(_: UIButton) {
      (self.model as? EditTagViewModel)?.deleteAction
         .apply(())
         .startWithNext {
            [weak self] _ in
            if let strongSelf = self {
               strongSelf.delegate?.didCompleteTagViewController(strongSelf)
            }
      }
   }

   @IBAction private func deleteTrainingsAction(_: UIButton) {
      (self.model as? EditTagViewModel)?.deleteTrainingsAction
         .apply(())
         .startWithCompleted {
      }
   }

   override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
      if self.model is EditTagViewModel {
         return TagSection.Delete.rawValue + 1
      }
      return TagSection.Information.rawValue + 1
   }

   override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if section == TagSection.Delete.rawValue && !self.model.hasTrainings.value {
         return 1
      }
      return super.tableView(tableView, numberOfRowsInSection: section)
   }
}

extension TagViewController: UICollectionViewDataSource, UICollectionViewDelegate {
   func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return self.colors.count
   }

   func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
      let cell: ColorCell = collectionView.dequeueCellForIndexPath(indexPath)
      cell.color = self.colors[indexPath.item]
      return cell
   }

   func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
      self.model.color.value = self.colors[indexPath.item]
   }
}
