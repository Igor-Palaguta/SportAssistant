import Foundation

private let _accelerationFormatter: NSNumberFormatter = {
   let formatter = NSNumberFormatter()
   formatter.maximumFractionDigits = 2
   return formatter
}()

extension NSNumberFormatter {
   static var accelerationFormatter: NSNumberFormatter {
      return _accelerationFormatter
   }

   class func formatAccelereration(acceleration: Double) -> String {
      return self.accelerationFormatter.stringFromNumber(NSNumber(double: acceleration))!
   }
}
