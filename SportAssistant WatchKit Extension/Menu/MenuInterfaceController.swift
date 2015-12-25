import WatchKit
import Foundation

class MenuInterfaceController: WKInterfaceController {
   @IBOutlet private weak var bestLabel: WKInterfaceLabel!

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      // Configure interface objects here.
   }

   override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }

   override func didAppear() {
      super.didAppear()

      self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(History.currentHistory.best))
   }
}
