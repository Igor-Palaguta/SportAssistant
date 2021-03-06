import Foundation
import HealthKit
import RealmSwift

extension StorageController {

   public var allTrainings: TrainingsCollection {
      return self.history
   }

   public func allTrainingsOrderedBy(orderBy: OrderBy, ascending: Bool) -> Results<Training> {
      return self.history.trainings.sorted(orderBy.fieldName, ascending: ascending)
   }

   public func trainingsForTags(tags: [Tag], orderBy: OrderBy, ascending: Bool) -> Results<Training> {
      let tagIds = tags.map { $0.id }
      let trainings = self.realm.objects(Training.self)
         .filter("SUBQUERY(tags, $tag, $tag.id IN %@).@count == \(tagIds.count)", tagIds)
         .sorted(orderBy.fieldName, ascending: ascending)
      return trainings
   }

   public func addTag(tag: Tag) {
      self.write {
         self.realm.add(tag)
      }
   }

   public func editTag(tag: Tag,
      name: String,
      activityType: HKWorkoutActivityType,
      color: UIColor) {
         self.write {
            tag.name = name
            tag.activityType = activityType
            tag.color = color
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

   func synchronizeTrainingWithId(id: String,
      start: NSDate,
      tagIds: [String],
      events: [AccelerationEvent]) {
         self.write {
            guard let training = self[id] else {
               let training = self.addTrainingWithId(id, start: start, tagIds: tagIds)
               self.history.appendEvents(events, toTraining: training)
               return
            }

            if events.count > training.events.count {
               let newEvents = events[training.events.count..<events.count]
               self.history.appendEvents(newEvents, toTraining: training)
            }
         }
   }

   public func addTrainingWithId(id: String, start: NSDate, tagIds: [String], activate: Bool = false) -> Training {
      var createdTraining: Training!
      self.write {
         createdTraining = self.realm.objectForPrimaryKey(Training.self, key: id)
         if createdTraining != nil {
            return
         }

         let tags: [Tag] = tagIds.flatMap { self.realm.objectForPrimaryKey(Tag.self, key: $0) }
         let trainingValue = ["id": id, "start": start, "tags": tags]
         let training = self.realm.create(Training.self, value: trainingValue, update: true)
         self.history.addTraining(training)
         tags.forEach { $0.addTraining(training) }
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
