import WatchKit
import Foundation

class TrainingController: NSObject {

   @IBOutlet private(set) weak var dateLabel: WKInterfaceLabel!
   @IBOutlet private(set) weak var resultLabel: WKInterfaceLabel!

   var training: Training! {
      didSet {
         let dateFormatter = NSDateFormatter()
         dateFormatter.dateStyle = .ShortStyle
         dateFormatter.timeStyle = .NoStyle
         self.dateLabel.setText(dateFormatter.stringFromDate(self.training.start))
         self.resultLabel.setText(NSNumberFormatter.formatAccelereration(self.training.best))
      }
   }
}
