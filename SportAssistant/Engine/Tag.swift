import Foundation
import RealmSwift

class Tag: Object {

   dynamic var name = ""

   convenience init(name: String) {
      self.init()
      self.name = name
   }
}
