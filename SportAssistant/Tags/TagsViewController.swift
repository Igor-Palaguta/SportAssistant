import UIKit

final class TagsViewController: UITableViewController {

   enum SelectionStyle {
      case Single(Tag)
      case Multiple([Tag])
   }

   enum Mode {
      case Navigator
      case Picker(TrainingFilter/*, Bool*/)

      private func accessoryForTag(tag: Tag?) -> UITableViewCellAccessoryType {
         switch self {
         case Navigator:
            return .DisclosureIndicator
         case Picker(.All/*, _*/):
            return tag == nil ? .Checkmark : .None
         case Picker(.SelectedTag(let selectedTag)):
            return selectedTag == tag ? .Checkmark : .None
         }
      }
   }

   var mode: Mode = .Navigator {
      didSet {
         self.tableView.reloadData()
      }
   }

   enum Action: Int {
      case Add
      case SelectAll
   }

   var actions: [Action] = [.Add, .SelectAll] {
      didSet {
         self.tableView.reloadData()
      }
   }

   typealias CompletionHandler = (TagsViewController) -> ()
   var completionHandler: CompletionHandler? {
      didSet {
         self.navigationItem.leftBarButtonItem = self.completionHandler != nil ? self.doneItem : nil
      }
   }

   private lazy var doneItem: UIBarButtonItem = {
      return UIBarButtonItem(barButtonSystemItem: .Done,
         target: self,
         action: Selector("completeAction:"))
   }()

   private lazy var tags = StorageController.UIController.tags

   override func viewDidLoad() {
      super.viewDidLoad()

      self.tableView.tableFooterView = UIView()
   }

   override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.tags.count + self.actions.count
   }

   private func tagAtIndexPath(indexPath: NSIndexPath) -> Tag? {
      let index = indexPath.row - self.actions.count
      return index >= 0 && index < self.tags.count ? self.tags[index] : nil
   }

   private func actionAtIndexPath(indexPath: NSIndexPath) -> Action? {
      return indexPath.row < self.actions.count
         ? self.actions[indexPath.row]
         : nil
   }

   private func indexPathForTag(tag: Tag) -> NSIndexPath? {
      guard let index = self.tags.indexOf(tag) else {
         return nil
      }

      return NSIndexPath(forRow: index + self.actions.count, inSection: 0)
   }

   override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
      if let action = self.actionAtIndexPath(indexPath) where action == .Add {
         let addCell: AddTagCell = tableView.dequeueCellForIndexPath(indexPath)
         return addCell
      }

      let cell: TagCell = tableView.dequeueCellForIndexPath(indexPath)
      let tag = self.tagAtIndexPath(indexPath)
      cell.nameLabel.text = tag?.name ?? tr(.AllTrainings)
      cell.accessoryType = self.mode.accessoryForTag(tag)

      return cell
   }

   override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
      return indexPath.row >= self.actions.count
   }

   override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {

      guard let tag = self.tagAtIndexPath(indexPath) else {
         return nil
      }

      let editAction = UITableViewRowAction(style: .Normal, title: tr(.Edit)) {
         _, indexPath in
         self.performSegue(StoryboardSegue.Main.Edit, sender: tag)
      }

      let deleteAction = UITableViewRowAction(style: .Destructive, title: tr(.Delete)) {
         _, indexPath in
         StorageController.UIController.removeTag(tag)
         ClientSynchronizer.defaultClient.synchronizeTags()
         tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      }

      return [editAction, deleteAction]
   }

   override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
      if indexPath.row == Action.Add.rawValue {
         self.performSegue(StoryboardSegue.Main.Add, sender: nil)
      } else if case .Navigator = self.mode {
         self.performSegue(StoryboardSegue.Main.Trainings, sender: self.tagAtIndexPath(indexPath))
      } else if let action = self.actionAtIndexPath(indexPath) where action == .Add {
         self.mode = .Picker(.All)
      } else if let tag = self.tagAtIndexPath(indexPath) {
         self.mode = .Picker(.SelectedTag(tag))
      }
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      let tag = sender as? Tag
      if let trainingsController = segue.destinationViewController as? TrainingsViewController {
         trainingsController.filter = tag.map { .SelectedTag($0) } ?? .All
         return
      }

      guard let tagController = segue.destinationViewController as? TagViewController else {
         return
      }

      tagController.delegate = self

      if let tag = tag {
         tagController.operation = .Edit(tag)
      } else {
         tagController.operation = .Add
      }
   }

   @objc private func completeAction(_: UIBarButtonItem) {
      self.completionHandler!(self)
   }
}

extension TagsViewController: TagViewControllerDelegate {

   func tagViewController(controller: TagViewController,
      didCompleteOperation operation: TagOperation,
      withTag tag: Tag) {
         guard let indexPath = self.indexPathForTag(tag) else {
            return
         }
         ClientSynchronizer.defaultClient.synchronizeTags()
         if case .Add = operation {
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
         } else {
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
         }
         self.navigationController?.popViewControllerAnimated(true)
   }
}
