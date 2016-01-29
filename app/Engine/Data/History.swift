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

   func appendEvents<T: SequenceType where T.Generator.Element == AccelerationEvent>(events: T, toTraining training: Training) {
      training.appendEvents(events)
      self.checkBestOfTraining(training)
   }
}

