import Foundation
import RealmSwift

class StorageController: NSObject {

   static var UIController: StorageController {
      assert(NSThread.isMainThread())
      return self._UIController
   }

   private static let _UIController = StorageController()

   private static let isPrepared: Bool = {
      let realm = try! Realm()
      if realm.objects(History).isEmpty {
         let history = History()
         let tableTennis = Tag(id: "1", name: "Table Tennis")
         let boxing = Tag(id: "2", name: "Boxing")
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

   dynamic var best: Double {
      return self.history.best
   }

   class func keyPathsForValuesAffectingBest() -> NSSet {
      return NSSet(object: "history.best")
   }

   dynamic var active: Training? {
      return self.history.active
   }

   class func keyPathsForValuesAffectingActive() -> NSSet {
      return NSSet(object: "history.active")
   }

   var tags: Results<Tag> {
      return self.realm.objects(Tag).sorted("lastUseDate", ascending: false)
   }

   var trainingsCount: Int {
      return self.history.trainings.count
   }

   func trainingsOrderedBy(orderBy: OrderBy, ascending: Bool) -> Results<Training> {
      return self.history.trainingsOrderedBy(orderBy, ascending: ascending)
   }

   private func write(@noescape transaction: () -> ()) {
      try! self.realm.write(transaction)
   }

   func addTrainingWithId(id: String, start: NSDate, tagId: String?, activate: Bool = false) -> Training {
      var createdTraining: Training!
      self.write {
         let tag: Tag? = tagId.flatMap { self.realm.objectForPrimaryKey(Tag.self, key: $0) }
         var trainingValue = ["id": id, "start": start]
         if let tag = tag {
            trainingValue["tag"] = tag
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
      data: [AccelerationData]) {
         self.write {
            if let training = self[id] {
               let newData = data[training.data.count..<data.count]
               self.history.appendDataFromArray(newData, toTraining: training)
            } else {
               let training = self.addTrainingWithId(id, start: start, tagId: tagId)
               self.history.appendDataFromArray(data, toTraining: training)
            }
         }
   }

   func deleteTraining(training: Training) {
      self.write {
         self.history.deleteTraining(training)
         training.tag?.deleteTraining(training)
         self.realm.delete(training)
      }
   }

   func deactivateTraining(training: Training) {
      self.write {
         self.history.deactivateTraining(training)
      }
   }

   func createTraining(tag: Tag?) -> Training {
      let training = Training()
      training.tag = tag
      self.write {
         self.history.addTraining(training)
         tag?.addTraining(training)
      }
      return training
   }

   func appendDataFromArray<T: SequenceType where T.Generator.Element == AccelerationData>(data: T, toTraining training: Training) {
      self.write {
         self.history.appendDataFromArray(data, toTraining: training)
         training.tag?.checkBestOfTraining(training)
      }
   }

   func addActivityWithName(name: String, toData data: AccelerationData) {
      self.write {
         let activity = Activity(name: name)
         data.activity = activity
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

   func addTag(tag: Tag) {
      self.write {
         self.realm.add(tag)
      }
   }

   func editTag(tag: Tag, name: String) {
      self.write {
         tag.name = name
      }
   }

   func removeTag(tag: Tag) {
      self.write {
         self.realm.delete(tag)
      }
   }

   func assignTags<T: SequenceType where T.Generator.Element == Tag>(tags: T) {
      self.write {
         let deleteTags = self.tags.filter {
            oldTag -> Bool in
            return !tags.contains {$0.id == oldTag.id}
         }
         if !deleteTags.isEmpty {
            self.realm.delete(deleteTags)
         }
         self.realm.add(tags, update: true)
      }
   }
}

