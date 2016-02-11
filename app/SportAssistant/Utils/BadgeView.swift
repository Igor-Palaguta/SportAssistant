import UIKit

final class BadgeView: UIView {

   dynamic var rounded: Bool = false {
      didSet {
         self.updateRoundedCorners()
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

   dynamic var color: UIColor? {
      set {
         super.backgroundColor = newValue
      }
      get {
         return super.backgroundColor
      }
   }

   private func updateRoundedCorners() {
      if self.rounded {
         let radius = min(self.bounds.midX, self.bounds.midY)
         self.layer.cornerRadius = radius
      }
   }

   override func awakeFromNib() {
      super.awakeFromNib()
      self.clipsToBounds = true
      self.updateRoundedCorners()
   }

   override func layoutSubviews() {
      super.layoutSubviews()
      self.updateRoundedCorners()
   }
}
