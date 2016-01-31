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

   lazy var realm = try! Realm()

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

   public var trainingsCount: Int {
      return self.history.trainings.count
   }

   public func trainingsOrderedBy(orderBy: OrderBy, ascending: Bool) -> Results<Training> {
      return self.history.trainingsOrderedBy(orderBy, ascending: ascending)
   }

   func write(@noescape transaction: () -> ()) {
      try! self.realm.write(transaction)
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

   public func appendEvents<T: SequenceType where T.Generator.Element == AccelerationEvent>(events: T, toTraining training: Training) {
      self.write {
         self.history.appendEvents(events, toTraining: training)
         training.tags.forEach { $0.checkBestOfTraining(training) }
      }
   }

   subscript(id: String) -> Training? {
      get {
         return self.realm.objectForPrimaryKey(Training.self, key: id)
      }
   }
}
