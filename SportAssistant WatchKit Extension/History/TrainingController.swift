import WatchKit
import Foundation

class TrainingController: NSObject {

   @IBOutlet private weak var dateLabel: WKInterfaceLabel!
   @IBOutlet private weak var resultLabel: WKInterfaceLabel!

   var interval: Interval! {
      didSet {
         let dateFormatter = NSDateFormatter()
         dateFormatter.dateStyle = .ShortStyle
         dateFormatter.timeStyle = .NoStyle
         self.dateLabel.setText(dateFormatter.stringFromDate(self.interval.start))
         self.resultLabel.setText(NSNumberFormatter.formatAccelereration(self.interval.best))
      }
   }
}
