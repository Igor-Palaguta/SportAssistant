import Foundation

extension NSTimeInterval {
   func toDurationString() -> String {
      let formatter = NSDateComponentsFormatter()
      let duration = max(self, 0)
      return formatter
         .stringFromTimeInterval(duration)!
         .stringByAppendingString(" s")
   }
}
