import UIKit

extension UIFont {

   enum Decoration {
      case None
      case Italic
   }

   enum UserFont: CustomStringConvertible {

      private static let name = "OpenSans"

      case Light(Decoration)
      case Regular(Decoration)
      case SemiBold(Decoration)
      case Bold(Decoration)

      var name: String {
         switch self {
         case Light(.None):
            return "OpenSans-Light"
         case Light(.Italic):
            return "OpenSansLight-Italic"
         case Regular(.None):
            return "OpenSans"
         case Regular(.Italic):
            return "OpenSans-Italic"
         case SemiBold(.None):
            return "OpenSans-Semibold"
         case SemiBold(.Italic):
            return "OpenSans-SemiboldItalic"
         case Bold(.None):
            return "OpenSans-Bold"
         case Bold(.Italic):
            return "OpenSans-BoldItalic"
         }
      }

      var description: String {
         return self.name
      }

      private static func allFontsWithDecoration(decoration: Decoration) -> [UserFont] {
         return [Light(decoration), Regular(decoration), SemiBold(decoration), Bold(decoration)]
      }

      private static let italicFonts: [UserFont] = UserFont.allFontsWithDecoration(.Italic)
      private static let regularFonts: [UserFont] = UserFont.allFontsWithDecoration(.None)
   }

   convenience init(userFont: UserFont, size: CGFloat) {
      let name = userFont.name
      self.init(name: name, size: size)!
   }

   func fontByAddingWeight(difference: Int, addingSize sizeDifference: CGFloat = 0) -> UIFont? {
      guard self.fontName.hasPrefix(UserFont.name) else {
         return nil
      }

      let isItalic = self.fontName.hasSuffix("Italic")
      let fonts = isItalic ? UserFont.italicFonts : UserFont.regularFonts

      guard let index = fonts.indexOf({ $0.name == self.fontName }) else {
         return nil
      }

      let newIndex = min(max(index + difference, 0), fonts.count - 1)

      return UIFont(userFont: fonts[newIndex], size: self.pointSize + sizeDifference)
   }
}


/*@objc
enum FontWeight: Int {
   case Light
   case Regular
   case SemiBold
   case Bold
}

extension UIFont {
   convenience init(weight: FontWeight, size: CGFloat) {
      self.init(name: UserFont.regularFonts[weight.rawValue].name, size: size)!
   }
}
*/