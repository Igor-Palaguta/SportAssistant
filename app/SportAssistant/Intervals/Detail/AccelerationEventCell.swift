import UIKit
import iOSEngine

class AccelerationEventCell: UITableViewCell, ReusableNibView {

   var event: AccelerationEvent! {
      didSet {
         self.timestampLabel.text = self.event.timestamp.toDurationString(true)
         self.activityLabel.text = self.event.activity?.name
         self.hiddenActivityConstraint.priority = self.event.activity == nil
            ? UILayoutPriorityDefaultHigh
            : UILayoutPriorityDefaultLow
         [(self.accelerationLabel, self.event.total),
            (self.xLabel, self.event.x),
            (self.yLabel, self.event.y),
            (self.zLabel, self.event.z)].forEach { label, value in
               label.attributedText = NSNumberFormatter.attributedStringForAcceleration(value,
                  integralFont: self.accelerationFont)
         }
      }
   }

   @IBOutlet private weak var timestampLabel: UILabel!
   @IBOutlet private weak var activityLabel: UILabel!
   @IBOutlet private weak var xLabel: UILabel!
   @IBOutlet private weak var yLabel: UILabel!
   @IBOutlet private weak var zLabel: UILabel!
   @IBOutlet private weak var accelerationLabel: UILabel!
   @IBOutlet private weak var hiddenActivityConstraint: NSLayoutConstraint!

   private lazy var accelerationFont: UIFont = self.accelerationLabel.font
}
