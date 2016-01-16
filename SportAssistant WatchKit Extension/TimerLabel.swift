import WatchKit
import Foundation

private class WeakTimer: NSObject {
   weak var timer: NSTimer?

   init(timer: NSTimer) {
      self.timer = timer
   }

   func invalidate() {
      self.timer?.invalidate()
      self.timer = nil
   }
}


private var timerAssociationKey: UInt8 = 0

let defaultSecondsFont = UIFont.systemFontOfSize(18)
let defaultMillisecondsFont = UIFont.systemFontOfSize(12)

extension WKInterfaceLabel {

   private var timer: WeakTimer? {
      get {
         return objc_getAssociatedObject(self, &timerAssociationKey) as? WeakTimer
      }
      set {
         objc_setAssociatedObject(self, &timerAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
   }

   func start(date: NSDate,
      secondsFont: UIFont = defaultSecondsFont,
      millisecondsFont: UIFont = defaultMillisecondsFont) {

         self.timer?.invalidate()

         let timer = NSTimer.scheduledTimerWithTimeInterval(0.1,
            target: self,
            selector: Selector("updateTimer:"),
            userInfo: ["startDate": date, "secondsFont": secondsFont, "millisecondsFont": millisecondsFont],
            repeats: true)

         self.timer = WeakTimer(timer: timer)

         self.setDuration(0, secondsFont: secondsFont, millisecondsFont: millisecondsFont)
   }

   func stop() {
      self.timer?.invalidate()
      self.timer = nil
   }

   func setDuration(duration: NSTimeInterval,
      secondsFont: UIFont = defaultSecondsFont,
      millisecondsFont: UIFont = defaultMillisecondsFont) {
         let formattedDuration = NSMutableAttributedString(string: duration.formattedSeconds(),
            attributes: [NSFontAttributeName: secondsFont])

         let formattedMilliseconds = NSAttributedString(string: duration.formattedMilliseconds(),
            attributes: [NSFontAttributeName: millisecondsFont])

         formattedDuration.appendAttributedString(formattedMilliseconds)

         self.setAttributedText(formattedDuration)
   }

   @objc private func updateTimer(timer: NSTimer) {
      if let userInfo = timer.userInfo as? [String: AnyObject],
         startDate = userInfo["startDate"] as? NSDate,
         secondsFont = userInfo["secondsFont"] as? UIFont,
         millisecondsFont = userInfo["millisecondsFont"] as? UIFont {
            let duration = NSDate().timeIntervalSinceDate(startDate)
            self.setDuration(duration, secondsFont: secondsFont, millisecondsFont: millisecondsFont)
      }
   }
}
