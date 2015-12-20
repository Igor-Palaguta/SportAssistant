import Foundation
import RealmSwift

class Interval: Object {
   dynamic var id: String = ""
   dynamic var best: Double = 0
   dynamic var start: NSDate?

   let data = List<AccelerationData>()

   func addData(data: AccelerationData) {
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
}
