import Foundation
import RealmSwift
import iOSEngine
import ReactiveCocoa
import Result

extension TagsFilter {
   private var name: String {
      switch self {
      case .Selected(let tags) where !tags.isEmpty:
         return tags.map { $0.name }.joinWithSeparator(", ")
      default:
         return tr(.AllTrainings)
      }
   }

   private var trainings: Results<Training> {
      let storage = StorageController.UIController
      switch self {
      case .Selected(let tags) where !tags.isEmpty:
         return storage.trainingsForTags(tags, orderBy: .Date, ascending: false)
      default:
         return storage.trainingsOrderedBy(.Date, ascending: false)
      }
   }

   var hasInvalidatedTag: Bool {
      switch self {
      case All:
         return false
      case .Selected(let tags):
         return tags.contains { $0.invalidated }
      }
   }

   func filterByRemovingInvalidatedTags() -> TagsFilter {
      switch self {
      case All:
         return self
      case .Selected(let tags):
         let validTags = tags.filter { !$0.invalidated }
         if validTags.count == tags.count {
            return self
         }
         return validTags.isEmpty ? . All : .Selected(validTags)
      }
   }
}

final class TrainingsViewModel {
   var filter = MutableProperty(TagsFilter.All)

   var name: SignalProducer<String, NoError> {
      return self.filter.producer.map { $0.name }
   }

   var best: SignalProducer<Double, NoError> {
      return self.results.map { $0.max("best") ?? 0 }
   }

   var results: SignalProducer<Results<Training>, NoError> {
      return self.filter.producer.flatMap(.Latest) {
         filter in
         return filter.trainings
            .changeSignal()
      }
   }

   var trainings: SignalProducer<[Training], NoError> {
      return self.results.map { Array($0) }
   }

   var isEmpty: SignalProducer<Bool, NoError> {
      return self.results.map { $0.isEmpty }
   }
}
