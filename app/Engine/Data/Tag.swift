import Foundation
import RealmSwift
import HealthKit

public final class Tag: TrainingsCollection, Equatable {

   public private(set) dynamic var id = NSUUID().UUIDString
   public internal(set) dynamic var name = ""
   public internal(set) dynamic var type = Int(HKWorkoutActivityType.Other.rawValue)
   dynamic var colorHex: String = UIColor.darkGrayColor().hex

   convenience init(id: String, name: String, activityType: HKWorkoutActivityType) {
      self.init()
      self.id = id
      self.name = name
      self.activityType = activityType
   }

   public convenience init(name: String, activityType: HKWorkoutActivityType, color: UIColor) {
      self.init()
      self.name = name
      self.activityType = activityType
      self.color = color
   }

   public override static func primaryKey() -> String? {
      return "id"
   }

   public override static func ignoredProperties() -> [String] {
      return ["activityType", "color"]
   }
}

public func == (lhs: Tag, rhs: Tag) -> Bool {
   return lhs.id == rhs.id
}

extension Tag: Hashable {
}

extension Tag {
   public var activityType: HKWorkoutActivityType {
      get {
         return HKWorkoutActivityType(rawValue: UInt(self.type)) ?? .Other
      }
      set {
         self.type = Int(newValue.rawValue)
      }
   }

   public dynamic var color: UIColor {
      get {
         return UIColor(hex: self.colorHex)
      }
      set {
         self.colorHex = newValue.hex
      }
   }

   class func keyPathsForValuesAffectingColor() -> NSSet {
      return NSSet(object: "colorHex")
   }
}
