import UIKit
import iOSEngine

private extension Array where Element: Equatable {
   func arrayByTogglingElement(element: Element) -> [Element] {
      var result: [Element] = self
      if let index = self.indexOf(element) {
         result.removeAtIndex(index)
      } else {
         result.append(element)
      }
      return result
   }

   func arrayByRemovingElement(element: Element) -> [Element] {
      if let index = self.indexOf(element) {
         var result: [Element] = self
         result.removeAtIndex(index)
         return result
      }
      return self
   }
}

enum TagsFilter {
   case All
   case Selected([Tag])

   var tags: [Tag] {
      switch self {
      case .All:
         return Array(StorageController.UIController.tags)
      case .Selected(let tags):
         return tags
      }
   }
}

final class TagsViewController: UITableViewController {

   enum Style {
      case Single
      case Multiple
   }

   enum Restrictions {
      case EmptyAllowed
      case EmptyNotAllowed
   }

   enum Mode {
      case Navigator
      case Picker(TagsFilter, Style, Restrictions)

      var tags: [Tag] {
         switch self {
         case Navigator:
            fatalError()
         case Picker(let filter, _, _):
            return filter.tags
         }
      }

      private func accessoryForAll() -> UITableViewCellAccessoryType {
         switch self {
         case Navigator:
            return .DisclosureIndicator
         case Picker(.All, _, _):
            return .Checkmark
         default:
            return .None
         }
      }

      private func isSelectedTag(tag: Tag) -> Bool {
         switch self {
         case Navigator:
            return false
         case Picker(.All, let style, _):
            return style == .Multiple
         case Picker(.Selected(let tags), _, _):
            return tags.contains(tag)
         }
      }

      private func accessoryForTag(tag: Tag) -> UITableViewCellAccessoryType {
         switch self {
         case Navigator:
            return .DisclosureIndicator
         case Picker(_):
            return self.isSelectedTag(tag) ? .Checkmark : .None
         }
      }

      private func modeWithFilter(filter: TagsFilter) -> Mode {
         guard case Picker(_, let style, let restrictions) = self else {
            fatalError()
         }

         if case .Selected(let selectedTags) = filter
            where style == .Multiple && selectedTags.count == TagsFilter.All.tags.count {
               return Picker(.All, style, restrictions)
         }

         return Picker(filter, style, restrictions)
      }

      private func modeByTogglingTag(tag: Tag) -> Mode {
         switch self {
         case Navigator:
            return self
         case Picker(_, .Multiple, .EmptyNotAllowed):
            let newTags = self.tags.arrayByTogglingElement(tag)
            return newTags.isEmpty ? self : self.modeWithFilter(.Selected(newTags))
         case Picker(_, .Multiple, .EmptyAllowed):
            let newTags = self.tags.arrayByTogglingElement(tag)
            return self.modeWithFilter(.Selected(newTags))
         case Picker(.All, .Single, _):
            return self.modeWithFilter(.Selected([tag]))
         case Picker(.Selected(let tags), .Single, .EmptyAllowed):
            if let selectedTag = tags.first where selectedTag == tag {
               return self.modeWithFilter(.Selected([]))
            } else {
               return self.modeWithFilter(.Selected([tag]))
            }
         case Picker(.Selected(let tags), .Single, .EmptyNotAllowed):
            if let selectedTag = tags.first where selectedTag == tag {
               return self
            } else {
               return self.modeWithFilter(.Selected([tag]))
            }
         default:
            fatalError()
         }
      }

      private func modeByTogglingAll() -> Mode {
         switch self {
         case Navigator:
            fatalError()
         case Picker(.All, _, .EmptyNotAllowed):
            return self
         case Picker(.All, _, .EmptyAllowed):
            return self.modeWithFilter(.Selected([]))
         case Picker(.Selected(_), _, _):
            return self.modeWithFilter(.All)
         default:
            fatalError()
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

   override func viewWillAppear(animated: Bool) {
      super.viewWillAppear(animated)
      //If changed from another screen
      self.tableView.reloadData()
   }

   override func shouldAutorotate() -> Bool {
      return true
   }

   override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
      return [.Portrait]
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
      let action = self.actionAtIndexPath(indexPath)
      if let action = action where action == .Add {
         let addCell: AddTagCell = tableView.dequeueCellForIndexPath(indexPath)
         return addCell
      }

      let cell: TagCell = tableView.dequeueCellForIndexPath(indexPath)
      if let action = action where action == .SelectAll {
         cell.nameLabel.text = tr(.AllTrainings)
         cell.trainingsCollection = StorageController.UIController.allTrainings
         cell.accessoryType = self.mode.accessoryForAll()
      } else if let tag = self.tagAtIndexPath(indexPath) {
         cell.nameLabel.text = tag.name
         cell.trainingsCollection = tag
         cell.accessoryType = self.mode.accessoryForTag(tag)
      } else {
         fatalError()
      }

      return cell
   }

   override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
      return self.tagAtIndexPath(indexPath) != nil
   }

   override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {

      guard let tag = self.tagAtIndexPath(indexPath) else {
         return nil
      }

      let editAction = UITableViewRowAction(style: .Normal, title: tr(.More)) {
         _, indexPath in
         self.performSegue(StoryboardSegue.Main.Edit, sender: tag)
      }

      if self.mode.isSelectedTag(tag) {
         return [editAction]
      }

      let deleteAction = UITableViewRowAction(style: .Destructive, title: tr(.Delete)) {
         _, indexPath in
         StorageController.UIController.deleteTag(tag)
         ClientSynchronizer.defaultClient.synchronizeTags()
         tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      }

      return [deleteAction, editAction]
   }

   override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
      if indexPath.row == Action.Add.rawValue {
         self.performSegue(StoryboardSegue.Main.Add, sender: nil)
      } else if case .Navigator = self.mode {
         self.performSegue(StoryboardSegue.Main.Trainings, sender: self.tagAtIndexPath(indexPath))
      } else if let action = self.actionAtIndexPath(indexPath) where action == .SelectAll {
         self.mode = self.mode.modeByTogglingAll()
      } else if let tag = self.tagAtIndexPath(indexPath) {
         self.mode = self.mode.modeByTogglingTag(tag)
      }
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      let tag = sender as? Tag
      if let tag = tag, trainingsViewController = segue.destinationViewController as? TrainingsViewController {
         trainingsViewController.filter = .Selected([tag])
      } else if let tagViewController = segue.destinationViewController as? TagViewController {
         tagViewController.delegate = self
         tagViewController.operation = tag.map { .Edit($0) } ?? .Add
      }
   }

   @objc private func completeAction(_: UIBarButtonItem) {
      self.completionHandler!(self)
   }
}

extension TagsViewController: TagViewControllerDelegate {

   func didCancelTagViewController(controller: TagViewController) {
      self.navigationController?.popViewControllerAnimated(true)
   }

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
