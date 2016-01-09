import WatchKit
import Foundation

final class TrainingController: NSObject {

   @IBOutlet private weak var dateLabel: WKInterfaceLabel!
   @IBOutlet private weak var resultLabel: WKInterfaceLabel!

   var interval: Interval! {
      didSet {
         let dateFormatter = NSDateFormatter()
         dateFormatter.dateStyle = .ShortStyle
         dateFormatter.timeStyle = .NoStyle
         self.dateLabel.setText(dateFormatter.stringFromDate(self.interval.start))
         self.resultLabel.setText(NSNumberFormatter.stringForAcceleration(self.interval.best))
         let isRecord = self.interval.best == HistoryController.mainThreadController.best

         let resultColor = isRecord
            ? UIColor(named: .Record)
            : UIColor.whiteColor()
         self.resultLabel.setTextColor(resultColor)
      }
   }
}
