import Foundation
import RealmSwift

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

class TrainingsCollection: Object {

   private(set) dynamic var lastUseDate: NSDate?
   private(set) dynamic var version = 0
   private(set) dynamic var best: Double = 0

   let trainings = List<Training>()

   var last: Training? {
      return self.trainings.last
   }

   func trainingsOrderedBy(orderBy: OrderBy, ascending: Bool) -> Results<Training> {
      return self.trainings.sorted(orderBy.fieldName, ascending: ascending)
   }

   func update(@noescape transaction: () -> ()) {
      transaction()
      self.version += 1
   }

   func addTraining(training: Training) {
      if self.trainings.indexOf(training) != nil {
         return
      }

      self.update {
         self.checkBestOfTraining(training)
         self.trainings.append(training)

         if let lastUseDate = self.lastUseDate where lastUseDate.compare(training.start) == .OrderedDescending {
            return
         }

         self.lastUseDate = training.start
      }
   }

   func deleteTraining(training: Training) {
      guard let index = self.trainings.indexOf(training) else {
         return
      }

      self.update {
         let isBest = self.best == training.best
         self.trainings.removeAtIndex(index)
         if isBest {
            self.best = self.trainings.max("best") ?? 0
         }
      }
   }

   func checkBestOfTraining(training: Training) {
      if training.best > self.best {
         self.best = training.best
      }
   }
}