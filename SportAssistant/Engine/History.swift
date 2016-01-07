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

   private func deleteInterval(interval: Interval) {
      guard let index = self.intervals.indexOf(interval) else {
         return
      }

      self.deactivateInterval(interval)
      self.intervals.removeAtIndex(index)
      self.intervalsCount = self.intervals.count

      if self.best == interval.best {
         self.best = self.intervals.max("best") ?? 0
      }
   }

   private func activateInterval(interval: Interval) {
      self.active = interval
   }

   private func deactivateInterval(interval: Interval) {
      if self.active == interval {
         self.active = nil
      }
   }

   private func appendData(data: AccelerationData, toInterval interval: Interval) {
      if data.total > self.best {
         self.best = data.total
      }

      interval.append(data)
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

   var intervals: Results<Interval> {
      return self.history.intervals.sorted("start", ascending: false)
   }

   func addInterval(interval: Interval, activate: Bool = false) {
      try! self.realm.write {
         self.history.addInterval(interval)
         if activate {
            self.history.activateInterval(interval)
         }
      }
   }

   func synchronizeIntervalWithId(id: String, start: NSDate, data: [AccelerationData]) {
      try! self.realm.write {
         if let interval = self[id] {
            let newData = data[interval.data.count..<data.count]
            interval.appendContentsOf(newData)
         } else {
            let interval = Interval(id: id, start: start)
            interval.appendContentsOf(data)
            self.history.addInterval(interval)
         }
      }
   }

   func deleteInterval(interval: Interval) {
      try! self.realm.write {
         self.history.deleteInterval(interval)
         self.realm.delete(interval)
      }
   }

   func deactivateInterval(interval: Interval) {
      try! self.realm.write {
         self.history.deactivateInterval(interval)
      }
   }

   func appendData<T: SequenceType where T.Generator.Element == AccelerationData>(data: T, toInterval interval: Interval) {
      try! self.realm.write {
         data.forEach {
            self.history.appendData($0, toInterval: interval)
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
