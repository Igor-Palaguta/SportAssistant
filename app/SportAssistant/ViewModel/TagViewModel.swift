import Foundation
import ReactiveCocoa
import Result
import iOSEngine
import HealthKit

struct TagState {
   let name: MutableProperty<String>
   let activityType: MutableProperty<HKWorkoutActivityType>
}

class TagViewModel {

   let name = MutableProperty("")
   let activityType = MutableProperty(HKWorkoutActivityType.Other)

   let isDefaultName = MutableProperty(true)
   let hasTrainings = MutableProperty(false)
   let trainingsCount = MutableProperty(0)

   let title: ConstantProperty<String>
   let saveAction: Action<TagState, (Tag, Bool), NoError>
   let deleteAction: Action<(), (), NoError>?
   let deleteTrainingsAction: Action<(), (), NoError>?

   var tagState: TagState {
      return TagState(name: self.name, activityType: self.activityType)
   }

   init(tag: Tag) {
      self.saveAction = Action {
         state in
         return SignalProducer {
            sink, disposable in
            let storage = StorageController.UIController
            storage.editTag(tag, name: state.name.value, activityType: state.activityType.value)
            sink.sendNext((tag, false))
            sink.sendCompleted()
         }
      }

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

      self.title = ConstantProperty(tr(.EditTag))
      self.name.value = tag.name
      self.activityType.value = tag.activityType
      self.isDefaultName.value = false

      self.hasTrainings <~ tag.trainings.changeSignal(sendImmediately: true)
         .map { return !$0.isEmpty }

      self.trainingsCount <~ tag.trainings.changeSignal(sendImmediately: true)
         .map { return $0.count }
   }

   init() {
      self.deleteAction = nil
      self.deleteTrainingsAction = nil
      self.saveAction = Action {
         state in
         return SignalProducer {
            sink, disposable in
            let storage = StorageController.UIController
            let tag = Tag(name: state.name.value, activityType: state.activityType.value)
            storage.addTag(tag)
            sink.sendNext((tag, true))
            sink.sendCompleted()
         }
      }

      self.title = ConstantProperty(tr(.AddTag))
      self.isDefaultName.value = true
   }
}
