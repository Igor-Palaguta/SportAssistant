import UIKit
import RealmSwift
import ReactiveCocoa

class TagsViewController: UITableViewController {

   private lazy var tags = HistoryController.mainThreadController.tags

   override func viewDidLoad() {
      super.viewDidLoad()

      DynamicProperty(object: HistoryController.mainThreadController, keyPath: "tagsVersion")
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
      }

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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
