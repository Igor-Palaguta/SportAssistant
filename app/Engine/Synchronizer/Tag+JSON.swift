import Foundation
import HealthKit

extension Tag {
   func toMessage() -> [String: AnyObject] {
      return ["id": id, "name": name, "type": type]
   }

   convenience init?(message: [String: AnyObject]) {
      guard let id = message["id"] as? String,
         name = message["name"] as? String,
         type = message["type"] as? Int,
         activityType = HKWorkoutActivityType(rawValue: UInt(type)) else {
            return nil
      }

      self.init(id: id, name: name, activityType: activityType)
   }
}
