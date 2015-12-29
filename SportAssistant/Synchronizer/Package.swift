import Foundation
import WatchConnectivity
import RealmSwift

private extension AccelerationData {
   func toMessage() -> [String: AnyObject] {
      var message = ["x": x, "y": y, "z": z, "date": date]
      if let activity = self.activity {
         message["activity"] = activity.toMessage()
      }
      return message
   }

   convenience init?(message: [String: AnyObject]) {
      guard let x = message["x"] as? Double,
         y = message["y"] as? Double,
         z = message["z"] as? Double,
         date = message["date"] as? NSDate else {
            return nil
      }

      self.init(x: x, y: y, z: z, date: date)
      let activityMessage = message["activity"] as? [String: AnyObject]
      self.activity = activityMessage.flatMap { Activity(message: $0) }
   }
}

private extension Activity {
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

enum Package {
   case Start(String)
   case Stop(String)
   case Data(String, [AccelerationData])

   func toMessage() -> [String: AnyObject] {
      switch self {
      case Start(let id):
         return ["start": id]
      case Stop(let id):
         return ["stop": id]
      case Data(let id, let data):
         return ["data": ["id": id, "data": data.map { $0.toMessage() }]]
      }
   }

   init?(name: String, arguments: AnyObject) {
      switch (name, arguments) {
      case ("start", let id as String):
         self = Start(id)
      case ("stop", let id as String):
         self = Stop(id)
      case ("data", let arguments as [String: AnyObject]):
         if let id = arguments["id"] as? String,
            dataMessage = arguments["data"] as? [[String: AnyObject]] {
               let data = dataMessage.flatMap { AccelerationData(message: $0) }
               self = Data(id, data)
         } else {
            return nil
         }
      default:
         return nil
      }
   }

   static func packageWithName(name: String, arguments: AnyObject) -> Package? {
      switch (name, arguments) {
      case ("start", let id as String):
         return Start(id)
      case ("stop", let id as String):
         return Stop(id)
      case ("data", let arguments as [String: AnyObject]):
         if let id = arguments["id"] as? String,
            dataMessage = arguments["data"] as? [[String: AnyObject]] {
               let data = dataMessage.flatMap { AccelerationData(message: $0) }
               return Data(id, data)
         }
      default:
         return nil
      }
      return nil
   }
}
