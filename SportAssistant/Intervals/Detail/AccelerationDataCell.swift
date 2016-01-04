import UIKit

class AccelerationDataCell: UITableViewCell, ReusableNibView {

   var data: AccelerationData! {
      didSet {
         self.activityLabel.text = self.data.activity?.name
         self.accelerationLabel.attributedText = NSNumberFormatter.attributedStringForAcceleration(self.data.total, integralFont: self.accelerationFont)
      }
   }

   @IBOutlet private(set) weak var timestampLabel: UILabel!
   @IBOutlet private weak var activityLabel: UILabel!
   @IBOutlet private weak var accelerationLabel: UILabel!

   private lazy var accelerationFont: UIFont = self.accelerationLabel.font
}
