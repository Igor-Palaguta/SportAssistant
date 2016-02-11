import UIKit
import ReactiveCocoa
import iOSEngine

final class BadgeView: UIView {

   override var backgroundColor: UIColor? {
      set {
         //do nothing
         //required if view inside cell. During selection color is clear
      }
      get {
         return super.backgroundColor
      }
   }

   private dynamic var color: UIColor? {
      set {
         super.backgroundColor = newValue
      }
      get {
         return super.backgroundColor
      }
   }

   private func updateRoundedCorners() {
      let radius = min(self.bounds.midX, self.bounds.midY)
      self.layer.cornerRadius = radius
   }

   override func awakeFromNib() {
      super.awakeFromNib()
      self.clipsToBounds = true
      self.color = .blackColor()
      self.updateRoundedCorners()
   }

   override func layoutSubviews() {
      super.layoutSubviews()
      self.updateRoundedCorners()
   }
}

final class TagCell: UITableViewCell, ReusableNibView {

   @IBOutlet private weak var nameLabel: UILabel!
   @IBOutlet private weak var countLabel: UILabel!
   @IBOutlet private weak var colorView: UIView!

   var model: TagViewModel! {
      didSet {
         DynamicProperty(object: self.nameLabel, keyPath: "text") <~
            self.model.name.producer
               .takeUntil(self.rac_prepareForReuseSignal.toVoidNoErrorSignalProducer())
               .map { $0 }

         DynamicProperty(object: self.colorView, keyPath: "color") <~
            self.model.color.producer
               .takeUntil(self.rac_prepareForReuseSignal.toVoidNoErrorSignalProducer())
               .map { $0 }

         DynamicProperty(object: self.countLabel, keyPath: "text") <~
            self.model.trainingsCount.producer
               .takeUntil(self.rac_prepareForReuseSignal.toVoidNoErrorSignalProducer())
               .map { "\($0)" }
      }
   }
}
