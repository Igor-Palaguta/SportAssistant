import Foundation
import RealmSwift

public final class Tag: TrainingsCollection, Equatable {

   public private(set) dynamic var id = NSUUID().UUIDString
   public internal(set) dynamic var name = ""

   convenience init(id: String, name: String) {
      self.init()
      self.id = id
      self.name = name
   }

   public convenience init(name: String) {
      self.init()
      self.name = name
   }

   public override static func primaryKey() -> String? {
      return "id"
   }
}

public func == (lhs: Tag, rhs: Tag) -> Bool {
   return lhs.id == rhs.id
}
