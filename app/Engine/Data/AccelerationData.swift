import Foundation
import RealmSwift

public enum AccelerationDataField: String {
   case x
   case y
   case z
   case total
}

public final class AccelerationData: Object {
   public private(set) dynamic var timestamp: Double = 0
   public private(set) dynamic var x: Double = 0
   public private(set) dynamic var y: Double = 0
   public private(set) dynamic var z: Double = 0
   public private(set) dynamic var total: Double = 0
   public dynamic var activity: Activity?

   public convenience init(x: Double, y: Double, z: Double, timestamp: Double) {
      self.init()
      self.x = x
      self.y = y
      self.z = z
      self.total = sqrt(x * x + y * y + z * z)
      self.timestamp = timestamp
   }

   public subscript(id: AccelerationDataField) -> Double {
      get {
         return self.valueForKey(id.rawValue) as! Double
      }
   }
}
