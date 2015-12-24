import Foundation
import RealmSwift

class Interval: Object {
   dynamic var id: String = NSUUID().UUIDString
   dynamic var best: Double = 0
   dynamic var start = NSDate()
   dynamic var active: Bool = true
   dynamic var totalCount: Int = 0
   dynamic var currentCount: Int = 0

   dynamic var duration: NSTimeInterval {
      let now = NSDate()
      let end = self.active || self.data.isEmpty ? now : self.data.last!.date
      return end.timeIntervalSinceDate(self.start)
   }

   let data = List<AccelerationData>()

   override static func primaryKey() -> String? {
      return "id"
   }

   override static func ignoredProperties() -> [String] {
      return ["duration"]
   }

   class func keyPathsForValuesAffectingDuration() -> NSSet {
      return NSSet(object: "active")
   }
}
