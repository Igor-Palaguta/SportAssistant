import Foundation

private struct Fields {
   static let x = "x"
   static let y = "y"
   static let z = "z"
   static let timestamp = "t"
   static let activity = "a"
}

extension AccelerationEvent {
   final func toJSON() -> [String: AnyObject] {
      var message: [String: AnyObject] = [Fields.x: x
         , Fields.y: y
         , Fields.z: z
         , Fields.timestamp: timestamp]
      if let activity = self.activity {
         message[Fields.activity] = activity.toJSON()
      }
      return message
   }

   static func parseJSON(message: [String: AnyObject]) -> AccelerationEvent? {
      guard let x = message[Fields.x] as? Double,
         y = message[Fields.y] as? Double,
         z = message[Fields.z] as? Double,
         timestamp = message[Fields.timestamp] as? Double else {
            return nil
      }

      let event = AccelerationEvent(x: x, y: y, z: z, timestamp: timestamp)
      let activityMessage = message[Fields.activity] as? [String: AnyObject]
      event.activity = activityMessage.flatMap { Activity.parseJSON($0) }
      return event
   }
}
