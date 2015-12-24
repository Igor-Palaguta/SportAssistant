import Foundation
import RealmSwift

class Interval: Object {
   dynamic var id = NSUUID().UUIDString
   dynamic var best: Double = 0
   dynamic var start = NSDate()
   dynamic var active = true
   dynamic var totalCount = 0
   dynamic var currentCount = 0

   dynamic var duration: NSTimeInterval {
      guard let lastData = self.data.last?.date else {
         return 0
      }

      return lastData.timeIntervalSinceDate(start)
   }

   var history: History {
      return self.linkingObjects(History.self, forProperty: "intervals").first!
   }

   let data = List<AccelerationData>()

   override static func primaryKey() -> String? {
      return "id"
   }

   override static func ignoredProperties() -> [String] {
      return ["duration", "history"]
   }

   class func keyPathsForValuesAffectingDuration() -> NSSet {
      return NSSet(objects: "active", "currentCount")
   }
}
