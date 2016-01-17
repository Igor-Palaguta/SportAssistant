import Foundation
import RealmSwift

class History: Object {
   private dynamic var best: Double = 0
   private dynamic var version = 0
   private dynamic var tagsVersion = 0
   private dynamic var active: Training?

   private func activateTraining(training: Training) {
      self.active = training
   }

   private func deactivateTraining(training: Training) {
      if self.active == training {
         self.active = nil
      }
   }

   private func appendDataFromArray<T: SequenceType where T.Generator.Element == AccelerationData>(data: T, toTraining training: Training) {
      training.appendDataFromArray(data)

      if training.best > self.best {
         self.best = training.best
      }
   }
}

enum OrderBy: String {
   case Date
   case Result

   private var fieldName: String {
      switch self {
      case Date:
         return "start"
      case Result:
         return "best"
      }
   }
}

class HistoryController: NSObject {

   static var mainThreadController: HistoryController {
      assert(NSThread.isMainThread())
      return self._mainThreadController
   }

   private static let _mainThreadController = HistoryController()

   private static let historyPrepared: Bool = {
      let realm = try! Realm()
      if !realm.objects(History).isEmpty {
         return true
      } else {
         let history = History()
         try! realm.write {
            realm.add(history)
         }
         return true
      }
   }()

   private lazy var realm = try! Realm()

   private dynamic lazy var history: History = {
      [unowned self] in
      guard HistoryController.historyPrepared else {
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

   dynamic var version: Int {
      return self.history.version
   }

   class func keyPathsForValuesAffectingVersion() -> NSSet {
      return NSSet(object: "history.version")
   }

   dynamic var tagsVersion: Int {
      return self.history.tagsVersion
   }

   class func keyPathsForValuesAffectingTagsVersion() -> NSSet {
      return NSSet(object: "history.tagsVersion")
   }

   dynamic var active: Training? {
      return self.history.active
   }

   class func keyPathsForValuesAffectingActive() -> NSSet {
      return NSSet(object: "history.active")
   }

   var tags: Results<Tag> {
      return self.realm.objects(Tag)
   }

   var trainings: Results<Training> {
      return self.realm.objects(Training)
   }

   func trainingsOrderedBy(orderBy: OrderBy, ascending: Bool) -> Results<Training> {
      return self.realm.objects(Training).sorted(orderBy.fieldName, ascending: ascending)
   }

   private func write(@noescape transaction: () -> ()) {
      try! self.realm.write(transaction)
   }

   func addTrainingWithId(id: String, start: NSDate, activate: Bool = false) -> Training {
      var createdTraining: Training!
      self.write {
         let training = self.realm.create(Training.self,
            value: ["id": id, "start": start],
            update: true)
         self.history.version += 1
         if activate {
            self.history.activateTraining(training)
         }
         createdTraining = training
      }
      return createdTraining
   }

   func synchronizeTrainingWithId(id: String, start: NSDate, data: [AccelerationData]) {
      self.write {
         if let training = self[id] {
            let newData = data[training.data.count..<data.count]
            self.history.appendDataFromArray(newData, toTraining: training)
         } else {
            let training = self.addTrainingWithId(id, start: start)
            self.history.appendDataFromArray(data, toTraining: training)
         }
      }
   }

   func deleteTraining(training: Training) {
      self.write {
         let isBest = self.best == training.best
         self.realm.delete(training)
         if isBest {
            self.history.best = self.trainings.max("best") ?? 0
         }
         self.history.version += 1
      }
   }

   func deactivateTraining(training: Training) {
      self.write {
         self.history.deactivateTraining(training)
      }
   }

   func createTraining() -> Training {
      let training = Training()
      self.write {
         self.realm.add(training)
         self.history.version += 1
      }
      return training
   }

   func appendDataFromArray<T: SequenceType where T.Generator.Element == AccelerationData>(data: T, toTraining training: Training) {
      self.write {
         self.history.appendDataFromArray(data, toTraining: training)
      }
   }

   func addActivityWithName(name: String, toData data: AccelerationData) {
      self.write {
         let activity = Activity(name: name)
         data.activity = activity
         self.realm.add(activity)
      }
   }

   func addTag(tag: Tag) {
      self.write {
         self.realm.add(tag)
         self.history.tagsVersion += 1
      }
   }

   subscript(id: String) -> Training? {
      get {
         return self.realm.objectForPrimaryKey(Training.self, key: id)
      }
   }
}
