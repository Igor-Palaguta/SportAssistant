import Foundation
import RealmSwift

class Interval: Object {
   dynamic var id = NSUUID().UUIDString
   dynamic var best: Double = 0
   dynamic var start: NSDate?
   dynamic var totalCount = 0
   dynamic var currentCount = 0

   dynamic var duration: NSTimeInterval {
      if let start = self.start, end = self.data.last?.date {
         return end.timeIntervalSinceDate(start)
      }
      return 0
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
      return NSSet(object: "currentCount")
   }
}
