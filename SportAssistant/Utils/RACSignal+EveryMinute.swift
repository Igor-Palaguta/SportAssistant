import Foundation
import ReactiveCocoa
import SwiftDate

func everyMinuteSignalProducer() -> SignalProducer<NSDate, NoError> {
   let now = NSDate()
   let secondsToNewMinute = now.endOf(.Minute, inRegion: .LocalRegion()).timeIntervalSinceDate(now)
   let nextMinuteSignal = RACSignal.interval(secondsToNewMinute, onScheduler: RACScheduler.mainThreadScheduler())

   let everyMinute = RACSignal.`return`(now)
      .concat(nextMinuteSignal)
      .concat(RACSignal.interval(60, onScheduler: RACScheduler.mainThreadScheduler()))

   return everyMinute.toSignalProducer()
      .map { $0 as! NSDate }
      .flatMapError { _ in SignalProducer<NSDate, NoError>.empty }
}

func everySecondSignalProducer() -> SignalProducer<NSDate, NoError> {
   let everySecond = RACSignal.interval(1, onScheduler: RACScheduler.mainThreadScheduler())

   return RACSignal.`return`(NSDate())
      .concat(everySecond)
      .toSignalProducer()
      .map { $0 as! NSDate }
      .flatMapError { _ in SignalProducer<NSDate, NoError>.empty }
}

extension RACSignal {
   func toVoidNoErrorSignalProducer() -> SignalProducer<(), NoError> {
      return self.toSignalProducer()
         .flatMapError { _ in SignalProducer.empty }
         .map { _ in () }
   }
}

extension NSObject {
   func rac_willDeallocSignalProducer() -> SignalProducer<(), NoError> {
      return self.rac_willDeallocSignal().toVoidNoErrorSignalProducer()
   }
}
