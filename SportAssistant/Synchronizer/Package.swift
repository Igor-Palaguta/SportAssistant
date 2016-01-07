import Foundation
import WatchConnectivity

private extension AccelerationData {
   func toMessage() -> [String: AnyObject] {
      var message: [String: AnyObject] = ["x": x, "y": y, "z": z, "timestamp": timestamp]
      if let activity = self.activity {
         message["activity"] = activity.toMessage()
      }
      return message
   }

   convenience init?(message: [String: AnyObject]) {
      guard let x = message["x"] as? Double,
         y = message["y"] as? Double,
         z = message["z"] as? Double,
         timestamp = message["timestamp"] as? Double else {
            return nil
      }

      self.init(x: x, y: y, z: z, timestamp: timestamp)
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
   case Start(String, NSDate)
   case Stop(String, Int)
   case Delete(String)
   case Data(String, Int, [AccelerationData])

   func toMessage() -> [String: AnyObject] {
      switch self {
      case Start(let id, let date):
         return ["start": ["id": id, "date": date]]
      case Stop(let id, let count):
         return ["stop": ["id": id, "count": count]]
      case Delete(let id):
         return ["delete": id]
      case Data(let id, let index, let data):
         return ["data": ["id": id, "index": index, "data": data.map { $0.toMessage() }]]
      }
   }

   init?(name: String, arguments: AnyObject) {
      switch (name, arguments) {
      case ("start", let arguments as [String: AnyObject]):
         if let id = arguments["id"] as? String,
            date = arguments["date"] as? NSDate {
               self = Start(id, date)
         } else {
            return nil
         }
      case ("stop", let arguments as [String: AnyObject]):
         if let id = arguments["id"] as? String,
            count = arguments["count"] as? Int {
               self = Stop(id, count)
         } else {
            return nil
         }
      case ("delete", let id as String):
         self = Delete(id)
      case ("data", let arguments as [String: AnyObject]):
         if let id = arguments["id"] as? String,
            index = arguments["index"] as? Int,
            dataMessage = arguments["data"] as? [[String: AnyObject]] {
               let data = dataMessage.flatMap { AccelerationData(message: $0) }
               self = Data(id, index, data)
         } else {
            return nil
         }
      default:
         return nil
      }
   }
}
