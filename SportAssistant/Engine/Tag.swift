import Foundation
import RealmSwift

final class Tag: TrainingsCollection {

   private(set) dynamic var id = NSUUID().UUIDString
   dynamic var name = ""

   convenience init(id: String, name: String) {
      self.init()
      self.id = id
      self.name = name
   }

   convenience init(name: String) {
      self.init()
      self.name = name
   }

   override static func primaryKey() -> String? {
      return "id"
   }
}
