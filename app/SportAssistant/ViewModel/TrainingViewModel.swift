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

      self.duration <~ DynamicProperty(object: training, keyPath: "duration")
         .producer
         .map { $0 as! NSTimeInterval }

      self.best <~ DynamicProperty(object: training, keyPath: "best")
         .producer
         .map { $0 as! Double }

      let tagsChangeSignal = DynamicProperty(object: training, keyPath: "tagsVersion")
         .producer
         .map { $0 as! Int }
         .skipRepeats()
         .map {
            [weak training] _ -> List<Tag>? in
            if let training = training {
               return training.tags
            }
            return nil
      }

      self.tags <~ tagsChangeSignal
         .map {
            tags in
            if let tags = tags {
               return tags.map { $0.name }.joinWithSeparator(", ")
            }
            return ""
      }

      self.hasTags <~ tagsChangeSignal
         .map {
            tags in
            if let tags = tags {
               return !tags.isEmpty
            }
            return false
      }

      self.start = ConstantProperty(training.start)
   }
}