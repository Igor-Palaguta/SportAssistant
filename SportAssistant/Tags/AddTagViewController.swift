import UIKit
import ReactiveCocoa

class AddTagViewController: UITableViewController {
   @IBOutlet private weak var nameField: UITextField!

   override func viewDidLoad() {
      super.viewDidLoad()

      let saveItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: Selector("addAction:"))
      DynamicProperty(object: saveItem, keyPath: "enabled") <~
         self.nameField.rac_textSignal()
            .toSignalProducer()
            .map { $0 as? String ?? "" }
            .map { !$0.isEmpty }
            .flatMapError { _ in SignalProducer.empty }

      self.navigationItem.rightBarButtonItem = saveItem
      self.tableView.tableFooterView = UIView()
   }

   @IBAction private func addAction(_: UIBarButtonItem) {
      let tag = Tag()
      tag.name = self.nameField.text!
      HistoryController.mainThreadController.addTag(tag)
   }
}
