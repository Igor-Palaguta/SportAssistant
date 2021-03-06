import Foundation
import ReactiveCocoa
import Result
import SwiftDate

func everyMinuteSignalProducer() -> SignalProducer<NSDate, NoError> {
   let now = NSDate()
   let secondsToNewMinute = now.endOf(.Minute, inRegion: DateRegion()).timeIntervalSinceDate(now)

   return SignalProducer(value: now)
      .concat(timer(secondsToNewMinute, onScheduler: QueueScheduler.mainQueueScheduler).take(1))
      .concat(timer(60, onScheduler: QueueScheduler.mainQueueScheduler))
}

func everySecondSignalProducer() -> SignalProducer<NSDate, NoError> {
   return SignalProducer(value: NSDate())
      .concat(timer(1, onScheduler: QueueScheduler.mainQueueScheduler))
}

extension RACSignal {
   func toNoErrorSignalProducer() -> SignalProducer<AnyObject?, NoError> {
      return self.toSignalProducer().flatMapError { _ in SignalProducer.empty }
   }

   func toVoidNoErrorSignalProducer() -> SignalProducer<(), NoError> {
      return self.toNoErrorSignalProducer()
         .map { _ in () }
   }
}

extension NSObject {
   func rac_willDeallocSignalProducer() -> SignalProducer<(), NoError> {
      return self.rac_willDeallocSignal().toVoidNoErrorSignalProducer()
   }
}
