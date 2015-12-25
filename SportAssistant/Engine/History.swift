import Foundation
import RealmSwift

class History: Object {
   dynamic var best: Double = 0
   dynamic var intervalsCount = 0
   dynamic var active: Interval?

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

      if data.total > interval.best {
         interval.best = data.total
      }

      if interval.data.isEmpty {
         interval.start = data.date
      }

      interval.data.append(data)
      interval.currentCount = interval.data.count
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
