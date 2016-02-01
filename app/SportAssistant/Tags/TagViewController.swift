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
   func tagViewController(controller: TagViewController, didAdd: Bool, tag: Tag)
}

final class TagViewController: UITableViewController {

   var model = TagViewModel()
   weak var delegate: TagViewControllerDelegate?

   @IBOutlet private weak var nameField: UITextField!
   @IBOutlet private weak var activityLabel: UILabel!
   @IBOutlet private weak var countLabel: UILabel!

   private lazy var saveAction: CocoaAction = {
      return CocoaAction(self.model.saveAction, input: self.model.tagState)
   }()

   override func viewDidLoad() {
      super.viewDidLoad()

      self.title = self.model.title.value
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
         if let strongSelf = self {
            strongSelf.delegate?.tagViewController(strongSelf, didAdd: isNew, tag: tag)
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
      self.model.deleteAction?.apply(()).startWithNext {
         [weak self] _ in
         if let strongSelf = self {
            strongSelf.delegate?.didCompleteTagViewController(strongSelf)
         }
      }
   }

   @IBAction private func deleteTrainingsAction(_: UIButton) {
      self.model.deleteTrainingsAction?.apply(()).startWithCompleted {
      }
   }

   override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
      if self.model.deleteAction != nil {
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
