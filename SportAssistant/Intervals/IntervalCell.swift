import UIKit
import ReactiveCocoa

class IntervalCell: UITableViewCell, ReusableNibView {
   @IBOutlet private weak var dateLabel: UILabel!
   @IBOutlet private weak var bestLast: UILabel!

   private static let dateFormatter: NSDateFormatter = {
      let dateFormatter = NSDateFormatter()
      dateFormatter.timeStyle = .ShortStyle
      dateFormatter.dateStyle = .ShortStyle
      return dateFormatter
   }()

   private static let resultFormatter: NSNumberFormatter = {
      let resultFormatter = NSNumberFormatter()
      resultFormatter.maximumSignificantDigits = 2
      resultFormatter.usesSignificantDigits = true
      return resultFormatter
   }()

   var interval: Interval! {
      didSet {
         if let interval = self.interval {
            self.dateLabel.text = interval.start.map {
               IntervalCell.dateFormatter.stringFromDate($0)
            }

            DynamicProperty(object: self.bestLast, keyPath: "text") <~
               DynamicProperty(object: interval, keyPath: "best").producer.map {
                  let best = $0 as! NSNumber
                  return IntervalCell.resultFormatter.stringFromNumber(best)
            }
         }
      }
   }
}
