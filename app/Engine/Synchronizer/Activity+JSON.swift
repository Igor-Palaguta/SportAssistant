import Foundation

extension Activity {
   func toMessage() -> [String: AnyObject] {
      return ["name": name]
   }

   convenience init?(message: [String: AnyObject]) {
      guard let name = message["name"] as? String else {
         return nil
      }

      self.init(name: name)
   }
}

