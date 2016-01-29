import UIKit
import HealthKit

struct WorkoutActivity {
   let type: HKWorkoutActivityType
   let name: String

   init(_ type: HKWorkoutActivityType, _ name: String) {
      self.type = type
      self.name = name
   }
}

extension HKWorkoutActivityType {
   var name: String {
      switch self {
      case Badminton:
         return tr(.Badminton)
      case Baseball:
         return tr(.Baseball)
      case .Boxing:
         return tr(.Boxing)
      case .Dance:
         return tr(.Dance)
      case .Golf:
         return tr(.Golf)
      case .Handball:
         return tr(.Handball)
      case .Squash:
         return tr(.Squash)
      case .TableTennis:
         return tr(.TableTennis)
      case .Tennis:
         return tr(.Tennis)
      case .Volleyball:
         return tr(.Volleyball)
      case .Other:
         return tr(.Other)
      default:
         return ""
      }
   }
}

class ActivitiesViewController: UITableViewController {

   var activityType: HKWorkoutActivityType = .Other

   private lazy var availableTypes: [HKWorkoutActivityType] = [.Badminton,
      .Baseball,
      .Boxing,
      .Dance,
      .Golf,
      .Handball,
      .Squash,
      .TableTennis,
      .Tennis,
      .Volleyball,
      .Other]

   override func viewWillAppear(animated: Bool) {
      super.viewWillAppear(animated)

      if self.activityType != .Other, let index = self.availableTypes.indexOf(self.activityType) {
         self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0),
            atScrollPosition: .Middle,
            animated: false)
      }
   }

   override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.availableTypes.count
   }

   override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
      let cell: ActivityCell = tableView.dequeueCellForIndexPath(indexPath)
      let type = self.availableTypes[indexPath.row]
      cell.textLabel!.text = type.name
      cell.accessoryType = self.activityType == type ? .Checkmark : .None
      return cell
   }

   override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
      self.activityType = self.availableTypes[indexPath.row]
      return indexPath
   }
}
