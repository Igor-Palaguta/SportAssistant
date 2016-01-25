import WatchKit
import Foundation
import watchOSEngine

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

   var training: Training! {
      didSet {

         self.dateLabel.setText(TrainingController.dateFormatter.stringFromDate(self.training.start))
         self.timeLabel.setText(TrainingController.timeFormatter.stringFromDate(self.training.start))

         let attributedAcceleration = NSNumberFormatter.attributedStringForAcceleration(self.training.best, integralFont: UIFont.systemFontOfSize(30))
         self.resultLabel.setAttributedText(attributedAcceleration)
         let isRecord = self.training.best == StorageController.UIController.best

         let resultColor = isRecord
            ? UIColor(named: .Record)
            : UIColor.whiteColor()
         self.resultLabel.setTextColor(resultColor)
      }
   }
}
