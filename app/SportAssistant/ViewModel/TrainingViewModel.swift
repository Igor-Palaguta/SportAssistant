import Foundation
import RealmSwift
import ReactiveCocoa
import iOSEngine

final class TrainingViewModel {
   let isActive = MutableProperty(false)
   let duration = MutableProperty<NSTimeInterval>(0)
   let best = MutableProperty<Double>(0)
   let tags = MutableProperty("")
   let hasTags = MutableProperty(false)

   let start: ConstantProperty<NSDate>

   let training: Training

   init(training: Training) {
      self.training = training

      self.isActive <~ DynamicProperty(object: StorageController.UIController, keyPath: "active")
         .producer
         .map { $0 as? Training }
         .map {
            active -> Bool in
            if let active = active {
               return active == training
            }
            return false
         }
         .skipRepeats()

      self.duration <~ training.events.changeSignal(sendImmediately: true)
         .map { [weak training] _ in training?.duration ?? 0 }

      self.best <~ DynamicProperty(object: training, keyPath: "best")
         .producer
         .map { $0 as! Double }

      let tagsChangeSignal = training.tags.changeSignal(sendImmediately: true)

      self.tags <~ tagsChangeSignal
         .map { $0.map { $0.name }.joinWithSeparator(", ") }

      self.hasTags <~ tagsChangeSignal
         .map { !$0.isEmpty }

      self.start = ConstantProperty(training.start)
   }
}