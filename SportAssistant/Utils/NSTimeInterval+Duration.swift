import Foundation

extension NSTimeInterval {

   private var fractional: NSTimeInterval {
      return self - Double(Int(self))
   }

   func formattedSeconds() -> String {
      let formatter = NSDateComponentsFormatter()
      let duration = max(self, 0)
      return formatter.stringFromTimeInterval(duration)!
   }

   func formattedMilliseconds() -> String {
      let duration = max(self, 0)
      let fractional = Int(duration.fractional * 10)
      return ".\(fractional)"
   }

   func toDurationString(showMilliseconds: Bool = false) -> String {
      var durationString = self.formattedSeconds()
      if showMilliseconds {
         durationString = durationString + self.formattedMilliseconds()
      }

      return durationString.stringByAppendingString(" s")
   }
}
