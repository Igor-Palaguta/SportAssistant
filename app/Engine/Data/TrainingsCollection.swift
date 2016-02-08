import Foundation
import RealmSwift

public enum OrderBy: Int {
   case Date
   case Result

   var fieldName: String {
      switch self {
      case Date:
         return "start"
      case Result:
         return "best"
      }
   }
}

public class TrainingsCollection: Object {

   public private(set) dynamic var lastUseDate: NSDate?
   public private(set) dynamic var best: Double = 0

   public let trainings = List<Training>()

   public var last: Training? {
      return self.trainings.last
   }

   public func trainingsOrderedBy(orderBy: OrderBy, ascending: Bool) -> Results<Training> {
      return self.trainings.sorted(orderBy.fieldName, ascending: ascending)
   }

   func update(@noescape transaction: () -> ()) {
      transaction()
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

   func recalculateBest() {
      self.best = self.trainings.max("best") ?? 0
   }

   func deleteTraining(training: Training) {
      guard let index = self.trainings.indexOf(training) else {
         return
      }

      self.update {
         let isBest = self.best == training.best
         self.trainings.removeAtIndex(index)
         if isBest {
            self.recalculateBest()
         }
      }
   }

   func deleteTrainings(trainings: [Training]) {
      self.update {
         var updateBest = false
         trainings.forEach {
            training in
            guard let index = self.trainings.indexOf(training) else {
               return
            }

            if !updateBest && self.best == training.best {
               updateBest = true
            }

            self.trainings.removeAtIndex(index)
         }

         if updateBest {
            self.recalculateBest()
         }
      }
   }

   func checkBestOfTraining(training: Training) {
      if training.best > self.best {
         self.best = training.best
      }
   }
}
