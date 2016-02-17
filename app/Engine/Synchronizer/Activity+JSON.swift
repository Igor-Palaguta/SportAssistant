import Foundation

private struct Fields {
   static let name = "n"
}

extension Activity {
   func toJSON() -> [String: AnyObject] {
      return [Fields.name: name]
   }

   static func parseJSON(message: [String: AnyObject]) -> Activity? {
      if let name = message[Fields.name] as? String {
         return Activity(name: name)
      }
      return nil
   }
}

