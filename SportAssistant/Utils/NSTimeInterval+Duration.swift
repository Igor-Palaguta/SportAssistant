import Foundation

extension NSTimeInterval {

   private var fractional: NSTimeInterval {
      return self - Double(Int(self))
   }

   func toDurationString(showMilliseconds: Bool = false) -> String {
      let formatter = NSDateComponentsFormatter()
      let duration = max(self, 0)

      var durationString = formatter.stringFromTimeInterval(duration)!
      if showMilliseconds {
         let fractional = Int(duration.fractional * 10)
         durationString = durationString.stringByAppendingString(".\(fractional)")
      }

      return durationString.stringByAppendingString(" s")
   }
}
