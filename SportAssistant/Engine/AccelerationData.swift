import Foundation
import RealmSwift

class AccelerationData: Object {
   dynamic var date: NSDate? = nil
   dynamic var x: Double = 0
   dynamic var y: Double = 0
   dynamic var z: Double = 0
   dynamic var total: Double = 0

   convenience init(x: Double, y: Double, z: Double) {
      self.init()
      self.x = x
      self.y = y
      self.z = z
      self.total = sqrt(x * x + y * y + z * z)
   }
}

let DidAddIntervalNotification = "DidAddIntervalNotification"
let DidChangeIntervalNotification = "DidChangeIntervalNotification"

extension Realm {
   private func intervalById(id: String) -> Interval {
      if let interval = self.objectForPrimaryKey(Interval.self, key: id) {
         return interval
      }

      let interval = Interval()
      interval.id = id
      return interval
   }

   func addAccelerationData(data: AccelerationData, intervalId: String) {
      if let interval = self.objectForPrimaryKey(Interval.self, key: intervalId) {
         try! self.write {
            interval.addData(data)
            NSNotificationCenter.defaultCenter().postNotificationName(DidChangeIntervalNotification, object: self, userInfo: ["id": intervalId, "data": data])
         }

      } else {
         let interval = Interval()
         interval.id = intervalId
         interval.addData(data)
         try! self.write {
            self.add(interval)
            NSNotificationCenter.defaultCenter().postNotificationName(DidAddIntervalNotification, object: self, userInfo: ["id": intervalId])
         }
      }

   }
}
