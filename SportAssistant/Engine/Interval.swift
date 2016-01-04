import Foundation
import RealmSwift

class Interval: Object {
   private(set) dynamic var id = NSUUID().UUIDString
   private(set) dynamic var best: Double = 0
   private(set) dynamic var start = NSDate()
   private(set) dynamic var currentCount = 0

   let data = List<AccelerationData>()

   dynamic var duration: NSTimeInterval {
      return self.data.last?.timestamp ?? 0
   }

   var activities: [Activity] {
      return self.data
         .filter(NSPredicate(format: "activity != nil"))
         .map { $0.activity! }
   }

   convenience init(id: String, start: NSDate) {
      self.init()
      self.id = id
      self.start = start
   }

   func addData(data: AccelerationData) {
      if data.total > self.best {
         self.best = data.total
      }

      self.data.append(data)
      self.currentCount = self.data.count
   }

   class func keyPathsForValuesAffectingDuration() -> NSSet {
      return NSSet(object: "currentCount")
   }

   override static func primaryKey() -> String? {
      return "id"
   }

   override static func ignoredProperties() -> [String] {
      return ["duration", "activities"]
   }
}
