import Foundation
import RealmSwift
import ReactiveCocoa
import Result

protocol ObservableCollection {
   func changeSignal(sendImmediately: Bool) -> SignalProducer<Self, NoError>
   func observeCollectionWithBlock(block: (Self) -> ()) -> NotificationToken
}

extension ObservableCollection {
   func changeSignal(sendImmediately: Bool = true) -> SignalProducer<Self, NoError> {
      return SignalProducer {
         sink, disposable in

         if sendImmediately {
            sink.sendNext(self)
         }

         var ignoreNext = sendImmediately
         let token = self.observeCollectionWithBlock {
            list in
            if !ignoreNext {
               sink.sendNext(list)
            } else {
               ignoreNext = false
            }
         }

         disposable.addDisposable {
            token.stop()
         }
         }.observeOn(UIScheduler())
   }
}

extension List: ObservableCollection {
   func observeCollectionWithBlock(block: (List) -> ()) -> NotificationToken {
      return self.addNotificationBlock(block)
   }
}

extension Results: ObservableCollection {
   func observeCollectionWithBlock(block: (Results) -> ()) -> NotificationToken {
      return self.addNotificationBlock {
         list, _ in
         if let list = list {
            block(list)
         }
      }
   }
}

extension Object {
   func invalidateSignal() -> SignalProducer<(), NoError> {
      return DynamicProperty(object: self, keyPath: "invalidated")
         .producer
         .map { $0 as! Bool }
         .filter { $0 }
         .map { _ in () }
   }
}
