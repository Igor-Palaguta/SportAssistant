import Foundation
import RealmSwift
import ReactiveCocoa
import Result

extension List {
   func changeSignal(sendImmediately sendImmediately: Bool = false) -> SignalProducer<List, NoError> {
      return SignalProducer {
         sink, disposable in

         if sendImmediately {
            sink.sendNext(self)
         }

         let token = self.addNotificationBlock {
            list in
            sink.sendNext(list)
         }

         disposable.addDisposable {
            token.stop()
         }
      }
   }
}

extension Results {
   func changeSignal(sendImmediately sendImmediately: Bool = false) -> SignalProducer<Results, NoError> {
      return SignalProducer {
         sink, disposable in

         if sendImmediately {
            sink.sendNext(self)
         }

         let token = self.addNotificationBlock {
            list, _ in
            if let list = list {
               sink.sendNext(list)
            }
         }

         disposable.addDisposable {
            token.stop()
         }
      }
   }
}
