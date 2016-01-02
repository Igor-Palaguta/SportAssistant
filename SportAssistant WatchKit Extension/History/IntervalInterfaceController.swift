import WatchKit
import Foundation

class IntervalInterfaceController: WKInterfaceController {

   @IBOutlet private weak var bestLabel: WKInterfaceLabel!
   @IBOutlet private weak var countLabel: WKInterfaceLabel!
   @IBOutlet private weak var durationLabel: WKInterfaceLabel!

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      let interval = context as! Interval
      self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(interval.best))
      self.durationLabel.setText(interval.duration.toDurationString())
      self.countLabel.setText(interval.activities.count.description)

      let historyController = HistoryController()
      if interval.best == historyController.best {
         self.bestLabel.setTextColor(.greenColor())
      }
   }

   override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }
}
