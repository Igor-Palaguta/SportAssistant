import Foundation
import RealmSwift

public final class Activity: Object {
   public internal(set) dynamic var name: String = ""
   convenience init(name: String) {
      self.init()
      self.name = name
   }
}
