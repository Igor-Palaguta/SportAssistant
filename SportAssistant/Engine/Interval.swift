import Foundation
import RealmSwift

class Interval: Object {
   dynamic var id: String = ""
   dynamic var best: Double = 0
   dynamic var start: NSDate?
   dynamic var completed: Bool = true
   dynamic var achievements: Achievements!

   let data = List<AccelerationData>()

   func addData(data: AccelerationData) {
      if data.acceleration > self.achievements.acceleration {
         self.achievements.acceleration = data.acceleration
      }

      if data.acceleration > self.best {
         self.best = data.acceleration
      }

      if self.start == nil {
         self.start = data.date
      }
      self.data.append(data)
   }

   override static func primaryKey() -> String? {
      return "id"
   }
}
