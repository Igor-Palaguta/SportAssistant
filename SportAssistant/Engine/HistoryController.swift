import Foundation
import RealmSwift

class HistoryController: NSObject {

   static var onceToken: dispatch_once_t = 0

   private lazy var realm = try! Realm()

   private lazy var history: History = {
      [unowned self] in
      var history: History?
      dispatch_once(&HistoryController.onceToken) {
         if let existentHistory = self.realm.objects(History).first {
            history = existentHistory
         } else {
            let newHistory = History()
            try! self.realm.write {
               self.realm.add(newHistory)
            }
            history = newHistory
         }
      }
      return history!
   }()

   dynamic var best: Double {
      return self.history.best
   }

   dynamic var intervalsCount: Int {
      return self.history.intervalsCount
   }

   var intervals: List<Interval> {
      return self.history.intervals
   }

   /*subscript(id: String) -> Interval? {
      get {
         return self.valueForKey(id.rawValue) as! Double
      }
   }*/
}
