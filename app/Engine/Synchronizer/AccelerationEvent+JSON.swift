import Foundation

extension AccelerationEvent {
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
