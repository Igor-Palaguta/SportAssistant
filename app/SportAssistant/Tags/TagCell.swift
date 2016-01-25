import UIKit
import ReactiveCocoa

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

   private var color: UIColor? {
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

   @IBOutlet private(set) weak var nameLabel: UILabel!
   @IBOutlet private weak var countLabel: UILabel!

   var trainingsCollection: TrainingsCollection! {
      didSet {
         guard let trainingsCollection = self.trainingsCollection else {
            return
         }

         DynamicProperty(object: self.countLabel, keyPath: "text") <~
            DynamicProperty(object: trainingsCollection, keyPath: "version")
               .producer
               .map { $0 as! Int }
               .skipRepeats()
               .map {
                  [weak trainingsCollection] _ in
                  return trainingsCollection.map { "\($0.trainings.count)" }
               }
               .takeUntil(self.rac_prepareForReuseSignal.toVoidNoErrorSignalProducer())
      }
   }

}