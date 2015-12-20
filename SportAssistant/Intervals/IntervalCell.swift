import UIKit
import ReactiveCocoa

final class IntervalCell: UITableViewCell, ReusableNibView {

   @IBOutlet private weak var dateLabel: UILabel!
   @IBOutlet private weak var durationLabel: UILabel!
   @IBOutlet private weak var bestLast: UILabel!

   private static let dateFormatter: NSDateFormatter = {
      let dateFormatter = NSDateFormatter()
      dateFormatter.timeStyle = .ShortStyle
      dateFormatter.dateStyle = .ShortStyle
      return dateFormatter
   }()

   private static let resultFormatter: NSNumberFormatter = {
      let resultFormatter = NSNumberFormatter()
      resultFormatter.maximumFractionDigits = 2
      //resultFormatter.usesSignificantDigits = true
      return resultFormatter
   }()

   var interval: Interval! {
      didSet {
         if let interval = self.interval {
            DynamicProperty(object: self.dateLabel, keyPath: "text") <~
               RACSignal.everyMinuteSignalProducer()
                  .takeUntil(self.rac_prepareForReuseSignal.toVoidNoErrorSignalProducer())
                  .map {
                     _ in
                     return interval.start.flatMap {
                        $0.toRelativeString()
                     }
                  }

            DynamicProperty(object: self.bestLast, keyPath: "text") <~
               DynamicProperty(object: interval, keyPath: "best").producer
                  .takeUntil(self.rac_prepareForReuseSignal.toVoidNoErrorSignalProducer())
                  .map {
                     let best = $0 as! NSNumber
                     return IntervalCell.resultFormatter.stringFromNumber(best)
            }
         }
      }
   }
}
