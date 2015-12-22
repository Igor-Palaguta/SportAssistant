import Foundation
import RealmSwift

class Interval: Object {
   dynamic var id: String = ""
   dynamic var best: Double = 0
   dynamic var start: NSDate!
   dynamic var completed: Bool = false
   dynamic var achievements: Achievements!

   dynamic var duration: NSTimeInterval {
      let end = self.completed ? self.data.last!.date : NSDate()
      return end.timeIntervalSinceDate(self.start)
   }

   let data = List<AccelerationData>()

   func addData(data: AccelerationData) {
      if data.total > self.achievements.acceleration {
         self.achievements.acceleration = data.total
      }

      if data.total > self.best {
         self.best = data.total
      }

      if self.start == nil {
         self.start = data.date
      }
      self.data.append(data)
   }

   override static func primaryKey() -> String? {
      return "id"
   }

   override static func ignoredProperties() -> [String] {
      return ["duration"]
   }

   class func keyPathsForValuesAffectingDuration() -> NSSet {
      return NSSet(object: "completed")
   }
}
