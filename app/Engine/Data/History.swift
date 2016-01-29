import Foundation
import RealmSwift

class History: TrainingsCollection {

   private(set) dynamic var active: Training?

   func activateTraining(training: Training) {
      self.active = training
   }

   func deactivateTraining(training: Training) {
      if self.active == training {
         self.active = nil
      }
   }

   func appendDataFromArray<T: SequenceType where T.Generator.Element == AccelerationEvent>(data: T, toTraining training: Training) {
      training.appendDataFromArray(data)
      self.checkBestOfTraining(training)
   }
}

