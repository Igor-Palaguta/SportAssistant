import UIKit
import ReactiveCocoa
import iOSEngine

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
