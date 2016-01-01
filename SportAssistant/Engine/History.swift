import Foundation
import RealmSwift

class History: Object {
   private dynamic var best: Double = 0
   private dynamic var intervalsCount = 0
   private dynamic var active: Interval?

   private let intervals = List<Interval>()

   private func addInterval(interval: Interval) {
      self.intervals.insert(interval, atIndex: 0)
      self.intervalsCount = self.intervals.count
   }

   private func activateInterval(interval: Interval) {
      self.active = interval
   }

   private func deactivateInterval(interval: Interval) {
      if self.active == interval {
         self.active = nil
      }
   }

   private func addData(data: AccelerationData, toInterval interval: Interval) {
      if data.total > self.best {
         self.best = data.total
      }

      interval.addData(data)
   }
}

class HistoryController: NSObject {

   static let historyPrepared: Bool = {
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
      assert(HistoryController.historyPrepared)
      return self.realm.objects(History).first!
      }()

   dynamic var best: Double {
      return self.history.best
   }

   class func keyPathsForValuesAffectingBest() -> NSSet {
      return NSSet(object: "history.best")
   }

   dynamic var intervalsCount: Int {
      return self.history.intervalsCount
   }

   class func keyPathsForValuesAffectingIntervalsCount() -> NSSet {
      return NSSet(object: "history.intervalsCount")
   }

   dynamic var active: Interval? {
      return self.history.active
   }

   class func keyPathsForValuesAffectingActive() -> NSSet {
      return NSSet(object: "history.active")
   }

   var intervals: List<Interval> {
      return self.history.intervals
   }

   func addInterval(interval: Interval, activate: Bool = false) {
      try! self.realm.write {
         self.history.addInterval(interval)
         if activate {
            self.history.activateInterval(interval)
         }
      }
   }

   func deactivateInterval(interval: Interval) {
      try! self.realm.write {
         self.history.deactivateInterval(interval)
      }
   }

   func addData(data: [AccelerationData], toInterval interval: Interval) {
      try! self.realm.write {
         data.forEach {
            self.history.addData($0, toInterval: interval)
         }
      }
   }

   func addActivityWithName(name: String, toData data: AccelerationData) {
      try! self.realm.write {
         let activity = Activity(name: name)
         data.activity = activity
         self.realm.add(activity)
      }
   }

   subscript(id: String) -> Interval? {
      get {
         return self.realm.objectForPrimaryKey(Interval.self, key: id)
      }
   }
}

