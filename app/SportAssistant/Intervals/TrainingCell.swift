import UIKit
import ReactiveCocoa

final class ProgressView: UIView {

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
   @IBOutlet private weak var progressView: ProgressView!
   @IBOutlet private weak var tagsView: UICollectionView!
   @IBOutlet private weak var tagPrefixLabel: UILabel!
   @IBOutlet private weak var hiddenTagsConstraint: NSLayoutConstraint!

   private lazy var accelerationFont: UIFont = self.bestLast.font
   private var recentWidth: CGFloat = 0

   var model: TrainingViewModel! {
      didSet {
         let reuseSignal = self.rac_prepareForReuseSignal.toVoidNoErrorSignalProducer()

         DynamicProperty(object: self.durationLabel, keyPath: "text") <~
            self.model.duration
               .producer
               .map { $0.toDurationString() }
               .takeUntil(reuseSignal)

         DynamicProperty(object: self.progressView, keyPath: "isAnimating") <~
            self.model.isActive
               .producer
               .map { $0 }
               .takeUntil(reuseSignal)

         DynamicProperty(object: self.dateLabel, keyPath: "text") <~
            self.model.start
               .producer
               .map { $0.toString(.ShortStyle) }
               .takeUntil(reuseSignal)

         let integralFont = self.accelerationFont
         DynamicProperty(object: self.bestLast, keyPath: "attributedText") <~
            self.model.best
               .producer
               .map {
                  best -> NSAttributedString? in
                  return NSNumberFormatter.attributedStringForAcceleration(best, integralFont: integralFont)
               }
               .takeUntil(reuseSignal)

         DynamicProperty(object: self.tagPrefixLabel, keyPath: "hidden") <~
            self.model.hasTags
               .producer
               .map { !$0 }
               .takeUntil(reuseSignal)

         DynamicProperty(object: self.hiddenTagsConstraint, keyPath: "priority") <~
            self.model.hasTags
               .producer
               .map { $0 ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh }
               .takeUntil(reuseSignal)

         self.tagsView.reloadData()
         self.tagsView.invalidateIntrinsicContentSize()
      }
   }

   override func layoutSubviews() {
      super.layoutSubviews()

      if self.frame.width != self.recentWidth && self.model.hasTags.value {
         self.tagsView.reloadData()
         self.tagsView.invalidateIntrinsicContentSize()
      }
      self.recentWidth = self.frame.width
   }
}

extension TrainingCell: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

   func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return self.model.training.tags.count
   }

   func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
      let cell: TagCollectionViewCell = collectionView.dequeueCellForIndexPath(indexPath)
      cell.trainingTag = self.model.tags.value[indexPath.item]
      return cell
   }

   func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
      let tagName = self.model.tags.value[indexPath.item].name

      let nameSize = tagName.sizeWithAttributes([NSFontAttributeName: self.bestLast.font])

      let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
      let maxWidth = floor(collectionView.frame.width - (flowLayout.sectionInset.left + flowLayout.sectionInset.right))

      let horizontalInsets: CGFloat = 4
      return CGRect(origin: .zero, size: CGSize(width: min(nameSize.width + horizontalInsets, maxWidth), height: nameSize.height)).integral.size
   }
}
