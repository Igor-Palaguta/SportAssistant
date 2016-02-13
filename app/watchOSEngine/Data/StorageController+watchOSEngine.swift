import Foundation
import RealmSwift

extension StorageController {
   public var recentTags: Results<Tag> {
      return self.realm.objects(Tag).sorted("lastUseDate", ascending: false)
   }

   public func createTraining(tag: Tag?) -> Training {
      let training = Training()
      if let tag = tag {
         training.tags.append(tag)
      }
      self.write {
         self.history.addTraining(training)
         tag?.addTraining(training)
      }
      return training
   }

   public func addActivityWithName(name: String, toEvent event: AccelerationEvent) {
      self.write {
         let activity = Activity(name: name)
         event.activity = activity
         self.realm.add(activity)
      }
   }

   func assignTags(tags: [Tag]) {
      self.write {
         let oldTags = self.tags.filter { !tags.contains($0) }
         if !oldTags.isEmpty {
            self.realm.delete(oldTags)
         }
         for tag in tags {
            if let existentTag = self.realm.objectForPrimaryKey(Tag.self, key: tag.id) {
               existentTag.name = tag.name
               existentTag.activityType = tag.activityType
               existentTag.colorHex = tag.colorHex
            } else {
               self.realm.add(tag)
            }
         }
      }
   }
}
