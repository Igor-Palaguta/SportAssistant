import UIKit
import ReactiveCocoa

class ProgressView: UIView {

   dynamic var isAnimating = false {
      didSet {
         if self.isAnimating {
            self.startAnimation()
         } else {
            self.stopAnimation()
         }
      }
   }

   override var backgroundColor: UIColor? {
      set {
         //do nothing
         //required if view inside cell. During selection color is clear
      }
      get {
         return super.backgroundColor
      }
   }

   private var color: UIColor? {
      set {
         super.backgroundColor = newValue
      }
      get {
         return super.backgroundColor
      }
   }

   override func awakeFromNib() {
      super.awakeFromNib()

      NSNotificationCenter.defaultCenter().rac_addObserverForName(UIApplicationDidBecomeActiveNotification,
         object: nil)
         .takeUntil(self.rac_willDeallocSignal())
         .subscribeNext {
            [weak self] _ in
            self?.restartAnimationIfNeeded()
      }
   }

   private func startAnimation() {
      self.color = .redColor()
      let fadeAnimation = CABasicAnimation(keyPath: "opacity")
      fadeAnimation.fromValue = 0
      fadeAnimation.toValue = 1
      fadeAnimation.autoreverses = true
      fadeAnimation.duration = 1
      fadeAnimation.repeatCount = Float.infinity
      self.layer.addAnimation(fadeAnimation, forKey: "progressAnimation")
   }

   private func stopAnimation() {
      self.color = .clearColor()
      self.layer.removeAnimationForKey("progressAnimation")
   }

   @objc private func restartAnimationIfNeeded() {
      if self.isAnimating {
         self.startAnimation()
      } else {
         self.stopAnimation()
      }
   }

   override func didMoveToWindow() {
      super.didMoveToWindow()

      self.restartAnimationIfNeeded()
   }
}

extension NSTimeInterval {
   func toDurationString() -> String {
      let formatter = NSDateComponentsFormatter()
      let duration = max(self, 0)
      return formatter
         .stringFromTimeInterval(duration)!
         .stringByAppendingString(" s")
   }
}

final class IntervalCell: UITableViewCell, ReusableNibView {

   @IBOutlet private weak var dateLabel: UILabel!
   @IBOutlet private weak var durationLabel: UILabel!
   @IBOutlet private weak var bestLast: UILabel!
   @IBOutlet private weak var progressView: ProgressView!

   private lazy var historyController = HistoryController()
   private lazy var accelerationFont: UIFont = self.bestLast.font

   var interval: Interval! {
      didSet {
         if let interval = self.interval {

            let reuseSignal = self.rac_prepareForReuseSignal.toVoidNoErrorSignalProducer()

            let activeSignal = DynamicProperty(object: self.historyController, keyPath: "active")
               .producer
               .map { $0 as? Interval }
               .map {
                  active -> Bool in
                  if let active = active {
                     return active == interval
                  }
                  return false
               }
               .skipRepeats()

            DynamicProperty(object: self.durationLabel, keyPath: "text") <~
               activeSignal
                  .flatMap(.Latest) {
                     active -> SignalProducer<NSTimeInterval, NoError> in
                     if active {
                        return everySecondSignalProducer().map { _ in interval.duration }
                     } else {
                        return SignalProducer(value: interval.duration)
                     }
                  }
                  .map { $0.toDurationString() }
                  .takeUntil(reuseSignal)

            DynamicProperty(object: self.progressView, keyPath: "isAnimating") <~
               activeSignal
                  .map { $0 }
                  .takeUntil(reuseSignal)

            DynamicProperty(object: self.dateLabel, keyPath: "text") <~
               DynamicProperty(object: interval, keyPath: "start").producer
                  .takeUntil(reuseSignal)
                  .map {
                     if let date = $0 as? NSDate {
                        return date.toString(.ShortStyle, inRegion: .LocalRegion())
                     }
                     return nil
            }

            let integralFont = self.accelerationFont
            DynamicProperty(object: self.bestLast, keyPath: "attributedText") <~
               DynamicProperty(object: interval, keyPath: "best").producer
                  .takeUntil(reuseSignal)
                  .map { $0 as! Double }
                  .map {
                     best -> NSAttributedString? in
                     return NSNumberFormatter.attributedStringForAcceleration(best, integralFont: integralFont)
            }
         }
      }
   }
}
