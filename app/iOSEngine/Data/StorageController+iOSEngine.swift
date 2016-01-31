import Foundation
import HealthKit
import RealmSwift

extension StorageController {

   public var allTrainings: TrainingsCollection {
      return self.history
   }

   public func addTag(tag: Tag) {
      self.write {
         self.realm.add(tag)
      }
   }

   public func editTag(tag: Tag, name: String, activityType: HKWorkoutActivityType) {
      self.write {
         tag.name = name
         tag.activityType = activityType
      }
   }

   public func deleteTrainingsOfTag(tag: Tag) {
      self.write {
         let trainings = Array(tag.trainings)
         if trainings.isEmpty {
            return
         }

         self.history.deleteTrainings(trainings)
         var affectedTags = Set<Tag>()
         trainings.forEach {
            training in
            training.tags.forEach {
               tag in
               if let index = tag.trainings.indexOf(training) {
                  tag.trainings.removeAtIndex(index)
                  affectedTags.insert(tag)
               }
            }
            self.realm.delete(training)
         }
         affectedTags.forEach {
            tag in
            tag.update { tag.recalculateBest() }
         }
      }
   }

   public func deleteTag(tag: Tag) {
      self.write {
         let trainings = tag.trainings
         trainings.forEach { $0.deleteTag(tag) }
         self.realm.delete(tag)
      }
   }

   public func assignTags(tags: [Tag], forTraining training: Training) {
      self.write {
         let oldTags = training.tags.filter { !tags.contains($0) }
         let newTags = tags.filter { !training.tags.contains($0) }

         oldTags.forEach { training.deleteTag($0) }
         newTags.forEach { training.addTag($0) }
      }
   }

   func synchronizeTrainingWithId(id: String,
      start: NSDate,
      tagId: String?,
      events: [AccelerationEvent]) {
         self.write {
            if let training = self[id] {
               let newEvents = events[training.events.count..<events.count]
               self.history.appendEvents(newEvents, toTraining: training)
            } else {
               let training = self.addTrainingWithId(id, start: start, tagId: tagId)
               self.history.appendEvents(events, toTraining: training)
            }
         }
   }

   public func addTrainingWithId(id: String, start: NSDate, tagId: String?, activate: Bool = false) -> Training {
      var createdTraining: Training!
      self.write {
         let tag: Tag? = tagId.flatMap { self.realm.objectForPrimaryKey(Tag.self, key: $0) }
         var trainingValue = ["id": id, "start": start]
         if let tag = tag {
            trainingValue["tags"] = [tag]
         }
         let training = self.realm.create(Training.self, value: trainingValue, update: true)
         self.history.addTraining(training)
         tag?.addTraining(training)
         if activate {
            self.history.activateTraining(training)
         }
         createdTraining = training
      }
      return createdTraining
   }

   func deactivateTraining(training: Training) {
      self.write {
         self.history.deactivateTraining(training)
      }
   }
}
