import Foundation
import UIKit

private let _accelerationFormatter: NSNumberFormatter = {
   let formatter = NSNumberFormatter()
   formatter.minimumIntegerDigits = 1
   formatter.maximumFractionDigits = 2
   return formatter
}()

extension NSNumberFormatter {
   static var accelerationFormatter: NSNumberFormatter {
      return _accelerationFormatter
   }

   class func stringForAcceleration(acceleration: Double) -> String {
      return self.accelerationFormatter.stringFromNumber(NSNumber(double: acceleration))!
   }

   class func attributedStringForAcceleration(acceleration: Double,
      integralAttributes: [String: AnyObject],
      fractionalAttributes: [String: AnyObject]) -> NSAttributedString {
         let formatter = self.accelerationFormatter
         let accelerationString = formatter.stringFromNumber(NSNumber(double: acceleration))!
         let attributedAcceleration = NSMutableAttributedString(string: accelerationString, attributes: integralAttributes)
         if let separatorRange = accelerationString.rangeOfString(formatter.decimalSeparator) {
            let fractionalPartRange =
            NSRange(location: accelerationString.startIndex.distanceTo(separatorRange.startIndex),
               length: separatorRange.startIndex.distanceTo(accelerationString.endIndex))
            attributedAcceleration.addAttributes(fractionalAttributes, range: fractionalPartRange)
         }
         return attributedAcceleration
   }

   class func attributedStringForAcceleration(acceleration: Double,
      integralFont: UIFont) -> NSAttributedString {
         let fractionalFont = integralFont.fontWithSize(integralFont.pointSize * 0.8)
         return self.attributedStringForAcceleration(acceleration, integralAttributes: [NSFontAttributeName: integralFont], fractionalAttributes: [NSFontAttributeName: fractionalFont])
   }
}
