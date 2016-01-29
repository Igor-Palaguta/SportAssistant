import Foundation
import HealthKit
import RealmSwift

public final class StorageController: NSObject {

   public static var UIController: StorageController {
      assert(NSThread.isMainThread())
      return self._UIController
   }

   private static let _UIController = StorageController()

   private static let isPrepared: Bool = {
      let realm = try! Realm()
      if realm.objects(History).isEmpty {
         let history = History()
         let tableTennis = Tag(id: "1", name: "Table Tennis", activityType: .TableTennis)
         let boxing = Tag(id: "2", name: "Boxing", activityType: .Boxing)
         try! realm.write {
            realm.add([history, tableTennis, boxing])
         }
         return true
      }
      assert(realm.objects(History).count == 1)
      return true
   }()

   private lazy var realm = try! Realm()

   dynamic lazy var history: History = {
      [unowned self] in
      guard StorageController.isPrepared else {
         fatalError()
      }
      return self.realm.objects(History).first!
      }()

   public dynamic var best: Double {
      return self.history.best
   }

   class func keyPathsForValuesAffectingBest() -> NSSet {
      return NSSet(object: "history.best")
   }

   public dynamic var active: Training? {
      return self.history.active
   }

   class func keyPathsForValuesAffectingActive() -> NSSet {
      return NSSet(object: "history.active")
   }

   public var tags: Results<Tag>  {
      return self.realm.objects(Tag)
   }

   public var allTrainings: TrainingsCollection {
      return self.history
   }

   public var recentTags: Results<Tag> {
      return self.realm.objects(Tag).sorted("lastUseDate", ascending: false)
   }

   public var trainingsCount: Int {
      return self.history.trainings.count
   }

   public func trainingsOrderedBy(orderBy: OrderBy, ascending: Bool) -> Results<Training> {
      return self.history.trainingsOrderedBy(orderBy, ascending: ascending)
   }

   public func trainingsWithPredicate(predicate: NSPredicate?) -> Results<Training> {
      if let predicate = predicate {
         return self.history.trainings.filter(predicate)
      } else {
         return self.realm.objects(Training.self)
      }
   }

   private func write(@noescape transaction: () -> ()) {
      try! self.realm.write(transaction)
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

   public func deleteTraining(training: Training) {
      self.write {
         self.history.deleteTraining(training)
         training.tags.forEach {
            $0.deleteTraining(training)
         }
         self.realm.delete(training)
      }
   }

   func deactivateTraining(training: Training) {
      self.write {
         self.history.deactivateTraining(training)
      }
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

   public func appendEvents<T: SequenceType where T.Generator.Element == AccelerationEvent>(events: T, toTraining training: Training) {
      self.write {
         self.history.appendEvents(events, toTraining: training)
         training.tags.forEach { $0.checkBestOfTraining(training) }
      }
   }

   public func addActivityWithName(name: String, toEvent event: AccelerationEvent) {
      self.write {
         let activity = Activity(name: name)
         event.activity = activity
         self.realm.add(activity)
      }
   }

   subscript(id: String) -> Training? {
      get {
         return self.realm.objectForPrimaryKey(Training.self, key: id)
      }
   }
}

extension StorageController {

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

   private func deleteTrainings(trainings: [Training]) {
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

   public func deleteTag(tag: Tag, withTrainings: Bool = false) {
      self.write {
         let trainings = Array(tag.trainings)
         trainings.forEach { $0.deleteTag(tag) }
         self.realm.delete(tag)
         if withTrainings {
            self.deleteTrainings(trainings)
         }
      }
   }

   func assignTags(tags: [Tag]) {
      self.write {
         let oldTags = self.tags.filter { !tags.contains($0) }
         let newTags = tags.filter { !self.tags.contains($0) }
         if !oldTags.isEmpty {
            self.realm.delete(oldTags)
         }
         if !newTags.isEmpty {
            self.realm.add(newTags)
         }
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
}

