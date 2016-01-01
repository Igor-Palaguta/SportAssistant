import Foundation
import RealmSwift

enum AccelerationDataField: String {
   case x
   case y
   case z
   case total
}

class AccelerationData: Object {
   private(set) dynamic var date: NSDate!
   private(set) dynamic var x: Double = 0
   private(set) dynamic var y: Double = 0
   private(set) dynamic var z: Double = 0
   private(set) dynamic var total: Double = 0
   dynamic var activity: Activity?

   convenience init(x: Double, y: Double, z: Double, date: NSDate) {
      self.init()
      self.date = date
      self.x = x
      self.y = y
      self.z = z
      self.total = sqrt(x * x + y * y + z * z)
   }

   subscript(id: AccelerationDataField) -> Double {
      get {
         return self.valueForKey(id.rawValue) as! Double
      }
   }
}
