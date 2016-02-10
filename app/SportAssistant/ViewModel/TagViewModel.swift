import Foundation
import ReactiveCocoa
import Result
import iOSEngine
import HealthKit

class BaseTagViewModel {
   let name = MutableProperty<String>("")
   let activityType = MutableProperty(HKWorkoutActivityType.Other)
}

final class TagViewModel: BaseTagViewModel {

   let trainingsCount = MutableProperty(0)

   init(tag: Tag) {
      super.init()

      self.name <~ DynamicProperty(object: tag, keyPath: "name")
         .producer
         .map { $0 as! String }

      self.activityType <~ DynamicProperty(object: tag, keyPath: "type")
         .producer
         .map { $0 as! Int }
         .map { HKWorkoutActivityType(rawValue: UInt($0))! }

      self.trainingsCount <~ tag.trainings.changeSignal()
         .takeUntil(tag.invalidateSignal())
         .map { $0.count }
   }

   override init() {
      super.init()
      self.name.value = tr(.AllTrainings)
      let allTrainings = StorageController.UIController.allTrainings
      self.trainingsCount <~ allTrainings.trainings.changeSignal()
         .map { $0.count }
   }
}

class EditableTagViewModel: BaseTagViewModel {
   let title: String
   typealias SaveAction = Action<BaseTagViewModel, (Tag, Bool), NoError>
   let saveAction: SaveAction
   let isDefaultName = MutableProperty(true)

   let hasTrainings = MutableProperty(false)
   let trainingsCount = MutableProperty(0)

   init(title: String, saveAction: SaveAction) {
      self.title = title
      self.saveAction = saveAction
   }
}

final class AddTagViewModel: EditableTagViewModel {
   init() {
      let saveAction: SaveAction = Action {
         model in
         return SignalProducer {
            sink, disposable in
            let storage = StorageController.UIController
            let tag = Tag(name: model.name.value, activityType: model.activityType.value)
            storage.addTag(tag)
            sink.sendNext((tag, true))
            sink.sendCompleted()
         }
      }
      super.init(title: tr(.AddTag), saveAction: saveAction)
   }
}

final class EditTagViewModel: EditableTagViewModel {

   let deleteAction: Action<(), (), NoError>
   let deleteTrainingsAction: Action<(), (), NoError>

   init(tag: Tag) {
      self.deleteAction = Action {
         _ in
         return SignalProducer {
            sink, disposable in
            StorageController.UIController.deleteTag(tag)
            ClientSynchronizer.defaultClient.sendTags()
            sink.sendNext(())
            sink.sendCompleted()
         }
      }

      self.deleteTrainingsAction = Action {
         _ in
         return SignalProducer {
            sink, disposable in
            StorageController.UIController.deleteTrainingsOfTag(tag)
            sink.sendNext(())
            sink.sendCompleted()
         }
      }

      let saveAction: SaveAction = Action {
         model in
         return SignalProducer {
            sink, disposable in
            let storage = StorageController.UIController
            storage.editTag(tag, name: model.name.value, activityType: model.activityType.value)
            sink.sendNext((tag, false))
            sink.sendCompleted()
         }
      }

      super.init(title: tr(.EditTag), saveAction: saveAction)

      self.name.value = tag.name
      self.activityType.value = tag.activityType
      self.isDefaultName.value = false

      let tagsChangeSignal = tag.trainings.changeSignal()
         .takeUntil(tag.invalidateSignal())

      self.hasTrainings <~ tagsChangeSignal.map { !$0.isEmpty }

      self.trainingsCount <~ tagsChangeSignal.map { $0.count }
   }
}
