import Foundation

extension SequenceType where Generator.Element: NSAttributedString {
   func joinWithSeparator(separator: NSAttributedString) -> NSAttributedString {
      return self.reduce(NSMutableAttributedString()) {
         result, string in
         if !result.string.isEmpty {
            result.appendAttributedString(separator)
         }
         result.appendAttributedString(string)
         return result
      }
   }

   func joinWithSeparator(separator: String) -> NSAttributedString {
      return joinWithSeparator(NSAttributedString(string: separator))
   }
}
