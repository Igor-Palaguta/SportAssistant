import Foundation
import RealmSwift

class AccelerationData: Object {
   dynamic var date: NSDate!
   dynamic var x: Double = 0
   dynamic var y: Double = 0
   dynamic var z: Double = 0
   dynamic var total: Double = 0

   convenience init(x: Double, y: Double, z: Double, date: NSDate) {
      self.init()
      self.date = date
      self.x = x
      self.y = y
      self.z = z
      self.total = sqrt(x * x + y * y + z * z)
   }
}
