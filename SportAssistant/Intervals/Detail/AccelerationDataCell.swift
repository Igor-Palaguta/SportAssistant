import UIKit

class AccelerationDataCell: UITableViewCell, ReusableNibView {

   var data: AccelerationData! {
      didSet {
         self.timestampLabel.text = self.data.timestamp.toDurationString(true)
         self.activityLabel.text = self.data.activity?.name
         self.hiddenActivityConstraint.priority = self.data.activity == nil ? 750 : 250
         [(self.accelerationLabel, self.data.total),
            (self.xLabel, self.data.x),
            (self.yLabel, self.data.y),
            (self.zLabel, self.data.z)].forEach { label, value in
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
