import Foundation
import WatchConnectivity

enum Package {
   case Tags([Tag])
   case Start(id: String, start: NSDate, tagId: String?)
   case Stop(id: String)
   case Synchronize(id: String, start: NSDate, tagId: String?, events: [AccelerationEvent])
   case Delete(id: String)
   case Events(id: String, position: Int, events: [AccelerationEvent])
   case ChangeTrainingTags(id: String, tagIds: [String])

   func toMessage() -> [String: AnyObject] {
      switch self {
      case Start(let id, let start, let tagId):
         var message = ["id": id, "start": start]
         if let tagId = tagId {
            message["tag"] = tagId
         }
         return ["start": message]
      case Synchronize(let id, let start, let tagId, let events):
         var message = ["id": id,
            "start": start,
            "events": events.map { $0.toMessage() }]
         if let tagId = tagId {
            message["tag"] = tagId
         }
         return ["synchronize": message]
      case Stop(let id):
         return ["stop": id]
      case Delete(let id):
         return ["delete": id]
      case Events(let id, let position, let events):
         return ["events": ["id": id, "position": position, "events": events.map { $0.toMessage() }]]
      case Tags(let tags):
         return ["tags": tags.map { $0.toMessage() }]
      case ChangeTrainingTags(let id, let tagIds):
         return ["change_tags": ["id": id, "tags": tagIds]]
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
            eventsMessage = arguments["events"] as? [[String: AnyObject]] {
               let events = eventsMessage.flatMap { AccelerationEvent(message: $0) }
               self = Synchronize(id: id,
                  start: start,
                  tagId: arguments["tag"] as? String,
                  events: events)
         } else {
            return nil
         }
      case ("stop", let id as String):
         self = Stop(id: id)
      case ("delete", let id as String):
         self = Delete(id: id)
      case ("events", let arguments as [String: AnyObject]):
         if let id = arguments["id"] as? String,
            position = arguments["position"] as? Int,
            eventsMessage = arguments["events"] as? [[String: AnyObject]] {
               let events = eventsMessage.flatMap { AccelerationEvent(message: $0) }
               self = Events(id: id, position: position, events: events)
         } else {
            return nil
         }
      case ("tags", let arguments as [[String: AnyObject]]):
         let tags = arguments.flatMap { Tag(message: $0) }
         self = .Tags(tags)
      case ("change_tags", let arguments as [String: AnyObject]):
         if let id = arguments["id"] as? String,
            tagIds = arguments["tags"] as? [String] {
               self = ChangeTrainingTags(id: id, tagIds: tagIds)
         } else {
            return nil
         }
      default:
         return nil
      }
   }
}
