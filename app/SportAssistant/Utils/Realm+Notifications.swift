import Foundation
import RealmSwift
import ReactiveCocoa
import Result

extension List {
   func changeSignal(sendImmediately: Bool = true) -> SignalProducer<List, NoError> {
      return SignalProducer {
         sink, disposable in

         if sendImmediately {
            sink.sendNext(self)
         }

         var ignoreNext = sendImmediately
         let token = self.addNotificationBlock {
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

extension Results {
   func changeSignal(sendImmediately: Bool = true) -> SignalProducer<Results, NoError> {
      return SignalProducer {
         sink, disposable in

         if sendImmediately {
            sink.sendNext(self)
         }

         var ignoreNext = sendImmediately
         let token = self.addNotificationBlock {
            list, _ in
            guard let list = list else {
               return
            }
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

extension Object {
   func invalidateSignal() -> SignalProducer<(), NoError> {
      return DynamicProperty(object: self, keyPath: "invalidated")
         .producer
         .map { $0 as! Bool }
         .filter { $0 }
         .map { _ in () }
   }
}
