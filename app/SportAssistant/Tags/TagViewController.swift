import UIKit
import HealthKit
import ReactiveCocoa
import iOSEngine

enum TagOperation {
   case Add
   case Edit(Tag)

   private var title: String {
      switch self {
      case .Add:
         return tr(.AddTag)
      case .Edit(_):
         return tr(.EditTag)
      }
   }

   private var name: String {
      if case .Edit(let tag) = self {
         return tag.name
      }
      return ""
   }

   private func processWithName(name: String, activityType: HKWorkoutActivityType) -> Tag {
      let storage = StorageController.UIController
      switch self {
      case .Add:
         let tag = Tag(name: name, activityType: activityType)
         storage.addTag(tag)
         return tag
      case .Edit(let tag):
         storage.editTag(tag, name: name, activityType: activityType)
         return tag
      }
   }
}

protocol TagViewControllerDelegate: class {
   func didCancelTagViewController(controller: TagViewController)
   func tagViewController(controller: TagViewController, didCompleteOperation operation: TagOperation, withTag tag: Tag)
}

private class TagViewModel {
   let name = MutableProperty<String>("")
   let activityType = MutableProperty<HKWorkoutActivityType>(.Other)
   let isDefaultName = MutableProperty<Bool>(true)
}

final class TagViewController: UITableViewController {

   var operation: TagOperation = .Add {
      didSet {
         if case .Edit(let tag) = self.operation {
            self.model.name.value = tag.name
            self.model.activityType.value = tag.activityType
            self.model.isDefaultName.value = false
         }
      }
   }

   weak var delegate: TagViewControllerDelegate?

   @IBOutlet private weak var nameField: UITextField!
   @IBOutlet private weak var activityLabel: UILabel!

   private var model = TagViewModel()

   override func viewDidLoad() {
      super.viewDidLoad()

      self.title = self.operation.title
      self.nameField.text = self.operation.name

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

      let saveItem = UIBarButtonItem(barButtonSystemItem: .Done,
         target: self,
         action: Selector("doneAction:"))

      DynamicProperty(object: saveItem, keyPath: "enabled") <~
         self.model.name
            .producer
            .map { !$0.isEmpty }

      combineLatest(self.model.activityType.producer, self.model.isDefaultName.producer)
         .filter { _, isDefaultName in isDefaultName }
         .map { type, _ in type }
         .skipRepeats()
         .startWithNext {
            [weak self] type in
            guard let strongSelf = self else {
               return
            }

            let suggestedName = type == .Other ? "" : type.name
            strongSelf.model.name.value = suggestedName
            strongSelf.nameField.text = suggestedName
      }

      self.navigationItem.rightBarButtonItem = saveItem

      self.tableView.tableFooterView = UIView()
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

   @IBAction private func doneAction(_: UIBarButtonItem) {
      let tag = self.operation.processWithName(self.model.name.value, activityType: self.model.activityType.value)
      self.delegate!.tagViewController(self,
         didCompleteOperation: self.operation,
         withTag: tag)
   }

   @IBAction private func cancelAction(_: UIBarButtonItem) {
      self.delegate!.didCancelTagViewController(self)
   }
}
