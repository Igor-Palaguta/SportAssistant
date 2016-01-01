import Foundation
import RealmSwift

class History: Object {
   private(set) dynamic var best: Double = 0
   private(set) dynamic var intervalsCount = 0
   private(set) dynamic var active: Interval?

   let intervals = List<Interval>()

   func addInterval(interval: Interval) {
      self.intervals.insert(interval, atIndex: 0)
      self.intervalsCount = self.intervals.count
   }

   func activateInterval(interval: Interval) {
      self.active = interval
   }

   func deactivateInterval(interval: Interval) {
      if self.active == interval {
         self.active = nil
      }
   }

   func addData(data: AccelerationData, toInterval interval: Interval) {
      if data.total > self.best {
         self.best = data.total
      }

      interval.addData(data)
   }

   static var currentHistory: History {
      let realm = try! Realm()
      return realm.currentHistory
   }
}

extension Realm {
   var currentHistory: History {
      return self.objects(History).first!
   }
}
