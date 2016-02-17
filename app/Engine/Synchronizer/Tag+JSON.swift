import Foundation
import HealthKit

private struct Fields {
   static let id = "id"
   static let name = "n"
   static let type = "t"
   static let color = "c"
}

extension Tag {
   func toJSON() -> [String: AnyObject] {
      return [Fields.id: id,
         Fields.name: name,
         Fields.type: type,
         Fields.color: colorHex]
   }

   static func parseJSON(message: [String: AnyObject]) -> Tag? {
      guard let id = message[Fields.id] as? String,
         name = message[Fields.name] as? String,
         colorHex = message[Fields.color] as? String,
         type = message[Fields.type] as? Int,
         activityType = HKWorkoutActivityType(rawValue: UInt(type)) else {
            return nil
      }

      return Tag(id: id,
         name: name,
         activityType: activityType,
         color: UIColor(hex: colorHex))
   }
}
