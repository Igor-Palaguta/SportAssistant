import UIKit

extension UIColor {
   var hex: String {
      var red: CGFloat = 0
      var green: CGFloat = 0
      var blue: CGFloat = 0
      var alpha: CGFloat = 0
      self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
      let hex = String(format: "#%02x%02x%02x%02x",
         Int(red * 0xFF),
         Int(green * 0xFF),
         Int(blue * 0xFF),
         Int(alpha * 0xFF))
      return hex
   }

   convenience init(hex: String) {
      assert(hex[hex.startIndex] == "#", "Expected hex string of format #RRGGBBAA")

      let scanner = NSScanner(string: hex)
      scanner.scanLocation = 1

      var rgba: UInt32 = 0
      scanner.scanHexInt(&rgba)

      self.init(rgba: rgba)
   }

   convenience init(rgba: UInt32) {
      self.init(red: CGFloat((rgba >> 24) & 0xFF)/255.0,
         green: CGFloat((rgba >> 16) & 0xFF)/255.0,
         blue: CGFloat((rgba >> 8) & 0xFF)/255.0,
         alpha: CGFloat(rgba & 0xFF)/255.0)
   }
}
