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

private extension Tag {
   func toMessage() -> [String: AnyObject] {
      return ["id": id, "name": name]
   }

   convenience init?(message: [String: AnyObject]) {
      guard let id = message["id"] as? String,
         name = message["name"] as? String else {
            return nil
      }

      self.init(id: id, name: name)
   }
}

enum Package {
   case Tags([Tag])
   case Start(id: String, start: NSDate, tagId: String?)
   case Stop(id: String)
   case Synchronize(id: String, start: NSDate, tagId: String?, data: [AccelerationData])
   case Delete(id: String)
   case Data(id: String, position: Int, data: [AccelerationData])

   func toMessage() -> [String: AnyObject] {
      switch self {
      case Start(let id, let start, let tagId):
         var message = ["id": id, "start": start]
         if let tagId = tagId {
            message["tag"] = tagId
         }
         return ["start": message]
      case Synchronize(let id, let start, let tagId, let data):
         var message = ["id": id,
            "start": start,
            "data": data.map { $0.toMessage() }]
         if let tagId = tagId {
            message["tag"] = tagId
         }
         return ["synchronize": message]
      case Stop(let id):
         return ["stop": id]
      case Delete(let id):
         return ["delete": id]
      case Data(let id, let position, let data):
         return ["data": ["id": id, "position": position, "data": data.map { $0.toMessage() }]]
      case Tags(let tags):
         return ["tags": tags.map { $0.toMessage() }]
      }
   }

   init?(name: String, arguments: AnyObject) {
      switch (name, arguments) {
      case ("start", let arguments as [String: AnyObject]):
         if let id = arguments["id"] as? String,
            start = arguments["start"] as? NSDate {
               self = Start(id: id, start: start, tagId: arguments["tag"] as? String)
         } else {
            return nil
         }
      case ("synchronize", let arguments as [String: AnyObject]):
         if let id = arguments["id"] as? String,
            start = arguments["start"] as? NSDate,
            dataMessage = arguments["data"] as? [[String: AnyObject]] {
               let data = dataMessage.flatMap { AccelerationData(message: $0) }
               self = Synchronize(id: id,
                  start: start,
                  tagId: arguments["tag"] as? String,
                  data: data)
         } else {
            return nil
         }
      case ("stop", let id as String):
         self = Stop(id: id)
      case ("delete", let id as String):
         self = Delete(id: id)
      case ("data", let arguments as [String: AnyObject]):
         if let id = arguments["id"] as? String,
            position = arguments["position"] as? Int,
            dataMessage = arguments["data"] as? [[String: AnyObject]] {
               let data = dataMessage.flatMap { AccelerationData(message: $0) }
               self = Data(id: id, position: position, data: data)
         } else {
            return nil
         }
      case ("tags", let arguments as [[String: AnyObject]]):
         let tags = arguments.flatMap { Tag(message: $0) }
         self = .Tags(tags)
      default:
         return nil
      }
   }
}
