import Foundation

extension Training {
   public final var userActivityInfo: [NSObject : AnyObject] {
      return ["id": self.id,
         "start": self.start,
         "tags": self.tags.map { $0.id }]
   }
}

extension NSUserActivity {
   public static var trainingType: String {
      return "com.spangleapp.Test.watchkitapp.watchkitextension.Training"
   }

   public final var trainingInfo: (id: String, start: NSDate, tags: [String])? {
      if self.activityType == NSUserActivity.trainingType,
         let userInfo = self.userInfo as? [String: AnyObject],
         id = userInfo["id"] as? String,
         start = userInfo["start"] as? NSDate,
         tags = userInfo["tags"] as? [String] {
            return (id, start, tags)
      }

      return nil
   }
}
