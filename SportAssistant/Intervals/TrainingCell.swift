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

      NSNotificationCenter.defaultCenter()
         .rac_addObserverForName(UIApplicationDidBecomeActiveNotification,
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

final class TrainingCell: UITableViewCell, ReusableNibView {

   @IBOutlet private weak var dateLabel: UILabel!
   @IBOutlet private weak var durationLabel: UILabel!
   @IBOutlet private weak var bestLast: UILabel!
   @IBOutlet private weak var tagLabel: UILabel!
   @IBOutlet private weak var progressView: ProgressView!
   @IBOutlet private weak var tagPrefixLabel: UILabel!
   @IBOutlet private weak var hiddenTagsConstraint: NSLayoutConstraint!

   private lazy var accelerationFont: UIFont = self.bestLast.font

   var training: Training! {
      didSet {
         if let training = self.training {

            let reuseSignal = self.rac_prepareForReuseSignal.toVoidNoErrorSignalProducer()

            let activeSignal = DynamicProperty(object: StorageController.UIController, keyPath: "active")
               .producer
               .map { $0 as? Training }
               .map {
                  active -> Bool in
                  if let active = active {
                     return active == training
                  }
                  return false
               }
               .skipRepeats()

            DynamicProperty(object: self.durationLabel, keyPath: "text") <~
               activeSignal
                  .flatMap(.Latest) {
                     active -> SignalProducer<NSTimeInterval, NoError> in
                     if active {
                        return everySecondSignalProducer().map { _ in training.duration }
                     } else {
                        return SignalProducer(value: training.duration)
                     }
                  }
                  .map { $0.toDurationString() }
                  .takeUntil(reuseSignal)

            DynamicProperty(object: self.progressView, keyPath: "isAnimating") <~
               activeSignal
                  .map { $0 }
                  .takeUntil(reuseSignal)

            DynamicProperty(object: self.dateLabel, keyPath: "text") <~
               DynamicProperty(object: training, keyPath: "start")
                  .producer
                  .takeUntil(reuseSignal)
                  .map {
                     if let date = $0 as? NSDate {
                        return date.toString(.ShortStyle, inRegion: .LocalRegion())
                     }
                     return nil
            }

            let integralFont = self.accelerationFont
            DynamicProperty(object: self.bestLast, keyPath: "attributedText") <~
               DynamicProperty(object: training, keyPath: "best")
                  .producer
                  .takeUntil(reuseSignal)
                  .map { $0 as! Double }
                  .map {
                     best -> NSAttributedString? in
                     return NSNumberFormatter.attributedStringForAcceleration(best, integralFont: integralFont)
            }

            DynamicProperty(object: self.tagLabel, keyPath: "text") <~
               DynamicProperty(object: training, keyPath: "tagsVersion")
                  .producer
                  .takeUntil(reuseSignal)
                  .map { $0 as! Int }
                  .skipRepeats()
                  .map {
                     [weak training] _ in
                     if let training = training {
                        return training.tags.map { $0.name }.joinWithSeparator(", ")
                     }
                     return nil
            }


            let hasTagsSignal = DynamicProperty(object: training, keyPath: "tagsVersion")
               .producer
               .takeUntil(reuseSignal)
               .map { $0 as! Int }
               .skipRepeats()
               .map {
                  [weak training] _ -> Bool in
                  if let training = training where !training.tags.isEmpty {
                     return true
                  }
                  return false
            }

            DynamicProperty(object: self.tagPrefixLabel, keyPath: "hidden") <~
               hasTagsSignal
                  .map { !$0 }

            DynamicProperty(object: self.hiddenTagsConstraint, keyPath: "priority") <~
               hasTagsSignal
                  .map { $0 ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh }
         }
      }
   }
}
