import UIKit
import ReactiveCocoa

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

   private func processWithName(name: String) -> Tag {
      let storage = StorageController.UIController
      switch self {
      case .Add:
         let tag = Tag(name: name)
         storage.addTag(tag)
         return tag
      case .Edit(let tag):
         storage.editTag(tag, name: name)
         return tag
      }
   }
}

protocol TagViewControllerDelegate: class {
   func tagViewController(controller: TagViewController, didCompleteOperation operation: TagOperation, withTag tag: Tag)
}

class TagViewController: UITableViewController {

   weak var delegate: TagViewControllerDelegate?

   var operation: TagOperation = .Add

   @IBOutlet private weak var nameField: UITextField!

   override func viewDidLoad() {
      super.viewDidLoad()

      self.title = self.operation.title
      self.nameField.text = self.operation.name

      let saveItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: Selector("doneAction:"))
      DynamicProperty(object: saveItem, keyPath: "enabled") <~
         self.nameField.rac_textSignal()
            .toSignalProducer()
            .map { $0 as? String ?? "" }
            .map { !$0.isEmpty }
            .flatMapError { _ in SignalProducer.empty }

      self.navigationItem.rightBarButtonItem = saveItem

      self.tableView.tableFooterView = UIView()
   }

   @IBAction private func doneAction(_: UIBarButtonItem) {
      let tag = self.operation.processWithName(self.nameField.text!)
      self.delegate?.tagViewController(self,
         didCompleteOperation: self.operation,
         withTag: tag)
   }
}
