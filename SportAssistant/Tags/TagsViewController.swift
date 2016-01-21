import UIKit
import RealmSwift
import ReactiveCocoa

class TagsViewController: UITableViewController {

   private lazy var tags = StorageController.UIController.tags

   override func viewDidLoad() {
      super.viewDidLoad()

      self.navigationItem.rightBarButtonItem = self.editButtonItem()
      self.tableView.tableFooterView = UIView()
   }

   override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.tags.count
   }

   override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
      let cell: TagCell = tableView.dequeueCellForIndexPath(indexPath)
      cell.nameLabel.text = self.tags[indexPath.row].name
      return cell
   }

   override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
      // Return false if you do not want the specified item to be editable.
      return true
   }

   override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
      if editingStyle == .Delete {
         let tag = self.tags[indexPath.row]
         StorageController.UIController.removeTag(tag)
         ClientSynchronizer.defaultClient.synchronizeTags()
         tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      }
   }

   override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
      let tag = self.tags[indexPath.row]
      if self.editing {
         self.performSegue(StoryboardSegue.Main.Edit, sender: tag)
      } else {
         self.performSegue(StoryboardSegue.Main.Trainings, sender: tag)
      }
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      if let tag = sender as? Tag {
         if let tagController = segue.destinationViewController as? TagViewController {
            tagController.operation = .Edit(tag)
            tagController.delegate = self
         } else if let trainingsController = segue.destinationViewController as? TrainingsViewController {
            trainingsController.title = tag.name
            trainingsController.trainingsCollection = tag
         }
      } else if let tagController = segue.destinationViewController as? TagViewController {
         tagController.operation = .Add
         tagController.delegate = self
      }
   }
}

extension TagsViewController: TagViewControllerDelegate {
   func didCancelTagViewController(controller: TagViewController) {
      self.navigationController?.popViewControllerAnimated(true)
   }

   func tagViewController(controller: TagViewController,
      didCompleteOperation operation: TagOperation,
      withTag tag: Tag) {
         guard let index = self.tags.indexOf(tag) else {
            return
         }
         ClientSynchronizer.defaultClient.synchronizeTags()
         let indexPath = [NSIndexPath(forRow: index, inSection: 0)]
         if case .Add = operation {
            self.tableView.insertRowsAtIndexPaths(indexPath, withRowAnimation: .Fade)
         } else {
            self.tableView.reloadRowsAtIndexPaths(indexPath, withRowAnimation: .Fade)
         }
         self.navigationController?.popViewControllerAnimated(true)
   }
}
