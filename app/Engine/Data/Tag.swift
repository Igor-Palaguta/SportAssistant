import Foundation
import RealmSwift
import HealthKit

public final class Tag: TrainingsCollection, Equatable {

   public private(set) dynamic var id = NSUUID().UUIDString
   public internal(set) dynamic var name = ""
   public dynamic var type = Int(HKWorkoutActivityType.Other.rawValue)

   public var activityType: HKWorkoutActivityType {
      get {
         return HKWorkoutActivityType(rawValue: UInt(self.type)) ?? .Other
      }
      set {
         self.type = Int(newValue.rawValue)
      }
   }

   convenience init(id: String, name: String, activityType: HKWorkoutActivityType) {
      self.init()
      self.id = id
      self.name = name
      self.activityType = activityType
   }

   public convenience init(name: String, activityType: HKWorkoutActivityType) {
      self.init()
      self.name = name
      self.activityType = activityType
   }

   public override static func primaryKey() -> String? {
      return "id"
   }

   public override static func ignoredProperties() -> [String] {
      return ["activityType"]
   }
}

public func == (lhs: Tag, rhs: Tag) -> Bool {
   return lhs.id == rhs.id
}

extension Tag: Hashable {
}
