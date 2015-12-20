import WatchKit
import Foundation

class TrainingController: NSObject {

   @IBOutlet private(set) weak var dateLabel: WKInterfaceLabel!
   @IBOutlet private(set) weak var resultLabel: WKInterfaceLabel!

   var training: Training! {
      didSet {
         //self.dateLabel.setText(self.training.movements.first!.description)
         //self.resultLabel.setText("\(self.training.result)")
      }
   }
}
