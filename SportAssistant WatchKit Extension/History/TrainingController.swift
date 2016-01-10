import WatchKit
import Foundation

final class TrainingController: NSObject {

   static let dateFormatter: NSDateFormatter = {
      let dateFormatter = NSDateFormatter()
      dateFormatter.dateStyle = .ShortStyle
      dateFormatter.timeStyle = .NoStyle
      return dateFormatter
   }()

   static let timeFormatter: NSDateFormatter = {
      let timeFormatter = NSDateFormatter()
      timeFormatter.dateStyle = .NoStyle
      timeFormatter.timeStyle = .ShortStyle
      return timeFormatter
   }()

   @IBOutlet private weak var dateLabel: WKInterfaceLabel!
   @IBOutlet private weak var timeLabel: WKInterfaceLabel!
   @IBOutlet private weak var resultLabel: WKInterfaceLabel!

   var interval: Interval! {
      didSet {

         self.dateLabel.setText(TrainingController.dateFormatter.stringFromDate(self.interval.start))
         self.timeLabel.setText(TrainingController.timeFormatter.stringFromDate(self.interval.start))

         let attributedAcceleration = NSNumberFormatter.attributedStringForAcceleration(self.interval.best, integralFont: UIFont.systemFontOfSize(30))
         self.resultLabel.setAttributedText(attributedAcceleration)
         let isRecord = self.interval.best == HistoryController.mainThreadController.best

         let resultColor = isRecord
            ? UIColor(named: .Record)
            : UIColor.whiteColor()
         self.resultLabel.setTextColor(resultColor)
      }
   }
}
