import Foundation
import RealmSwift

class Activity: Object {
   dynamic var name: String = ""
   convenience init(name: String) {
      self.init()
      self.name = name
   }
}
