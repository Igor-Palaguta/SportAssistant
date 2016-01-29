import Foundation
import WatchConnectivity

enum Package {
   case Tags([Tag])
   case Start(id: String, start: NSDate, tagId: String?)
   case Stop(id: String)
   case Synchronize(id: String, start: NSDate, tagId: String?, data: [AccelerationEvent])
   case Delete(id: String)
   case Data(id: String, position: Int, data: [AccelerationEvent])

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
               let data = dataMessage.flatMap { AccelerationEvent(message: $0) }
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
               let data = dataMessage.flatMap { AccelerationEvent(message: $0) }
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
