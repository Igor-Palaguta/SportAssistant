import UIKit
import RealmSwift
import ReactiveCocoa

class TagsViewController: UITableViewController {

   private lazy var tags = HistoryController.mainThreadController.tags

   override func viewDidLoad() {
      super.viewDidLoad()

      /*DynamicProperty(object: HistoryController.mainThreadController, keyPath: "tagsVersion")
         .producer
         .takeUntil(self.rac_willDeallocSignal().toVoidNoErrorSignalProducer())
         .map { $0 as! Int }
         .skip(1)
         .skipRepeats()
         .startWithNext {
            [weak self] _ in
            if let strongSelf = self {
               strongSelf.tableView.reloadData()
            }
      }*/

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
         HistoryController.mainThreadController.removeTag(tag)
         tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      }
   }

   /*
   // Override to support rearranging the table view.
   override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

   }
   */

   //override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
   //   return true
   //}

   override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
      if self.editing {
         let tag = self.tags[indexPath.row]
         self.performSegue(StoryboardSegue.Main.Edit, sender: tag)
      }
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      guard let tagController = segue.destinationViewController as? TagViewController else {
         return
      }

      if let tag = sender as? Tag where segue.identifier == StoryboardSegue.Main.Edit.rawValue {
         tagController.operation = .Edit(tag)
      } else if segue.identifier == StoryboardSegue.Main.Add.rawValue {
         tagController.operation = .Add
      } else {
         fatalError()
      }

      tagController.delegate = self
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
         let indexPath = [NSIndexPath(forRow: index, inSection: 0)]
         if case .Add = operation {
            self.tableView.insertRowsAtIndexPaths(indexPath, withRowAnimation: .Fade)
         } else {
            self.tableView.reloadRowsAtIndexPaths(indexPath, withRowAnimation: .Fade)
         }
         self.navigationController?.popViewControllerAnimated(true)
   }
}
