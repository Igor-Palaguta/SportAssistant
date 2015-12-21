import UIKit
import ReactiveCocoa

private extension UIView {
   func startRecordAnimation() {
      self.hidden = false
      let fadeAnimation = CABasicAnimation(keyPath: "opacity")
      fadeAnimation.fromValue = 0
      fadeAnimation.toValue = 1
      fadeAnimation.autoreverses = true
      fadeAnimation.duration = 1
      fadeAnimation.repeatCount = Float.infinity
      self.layer.addAnimation(fadeAnimation, forKey: "recordingAnimation")
   }

   func stopRecordAnimation() {
      self.hidden = true
      self.layer.removeAnimationForKey("recordingAnimation")
   }
}

final class IntervalCell: UITableViewCell, ReusableNibView {

   @IBOutlet private weak var dateLabel: UILabel!
   @IBOutlet private weak var durationLabel: UILabel!
   @IBOutlet private weak var bestLast: UILabel!
   @IBOutlet private weak var progressView: UIView!

   private static let dateFormatter: NSDateFormatter = {
      let dateFormatter = NSDateFormatter()
      dateFormatter.timeStyle = .ShortStyle
      dateFormatter.dateStyle = .ShortStyle
      return dateFormatter
   }()

   private class func formatDuration(duration: NSTimeInterval, parts: [Int]) -> String {
      let seconds = Int(duration)
      var componentValue = seconds
      var components = parts.flatMap {
         divider -> Int? in
         if componentValue == 0 {
            return nil
         }

         let value = componentValue % divider
         componentValue /= divider
         return value
      }

      if componentValue > 0 || components.isEmpty {
         components.append(componentValue)
      }

      return components.reverse().map {
         String(format: "%02d", arguments: [$0])
      }.joinWithSeparator(":").stringByAppendingString(" s")
   }

   private class func formatDuration(duration: NSTimeInterval) -> String {
      return self.formatDuration(duration, parts: [60, 60])
   }

   var interval: Interval! {
      didSet {
         if let interval = self.interval {
            let reuseSignal = self.rac_prepareForReuseSignal.toVoidNoErrorSignalProducer()

            let completedSignal = DynamicProperty(object: interval, keyPath: "completed")
               .producer
               .takeUntil(reuseSignal)
               .map { $0 as! Bool }
               .skipRepeats()

            DynamicProperty(object: self.durationLabel, keyPath: "text") <~
               completedSignal
                  .flatMap(.Latest) {
                     completed -> SignalProducer<NSTimeInterval, NoError> in
                     if completed {
                        return SignalProducer(value: interval.duration)
                     } else {
                        return everySecondSignalProducer().map { _ in interval.duration }
                     }
                  }.map {
                     return IntervalCell.formatDuration($0)
            }

            completedSignal.startWithNext {
               [weak progressView = self.progressView] completed in
               if completed {
                  progressView?.stopRecordAnimation()
               } else {
                  progressView?.startRecordAnimation()
               }
            }

            self.dateLabel.text = interval.start.toString(.ShortStyle)

            DynamicProperty(object: self.bestLast, keyPath: "text") <~
               DynamicProperty(object: interval, keyPath: "best").producer
                  .takeUntil(reuseSignal)
                  .map {
                     let best = $0 as! Double
                     return NSNumberFormatter.formatAccelereration(best)
            }
         }
      }
   }
}
