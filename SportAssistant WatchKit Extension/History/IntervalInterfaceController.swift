import WatchKit
import Foundation

protocol IntervalInterfaceControllerDelegate: class {
   func deleteIntervalInterfaceController(controller: IntervalInterfaceController)
}

final class IntervalInterfaceController: WKInterfaceController {

   private weak var delegate: IntervalInterfaceControllerDelegate?

   private(set) var interval: Interval! {
      didSet {
         self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(interval.best))
         self.durationLabel.setText(interval.duration.toDurationString())
         self.countLabel.setText(interval.activities.count.description)

         if interval.best == HistoryController.mainThreadController.best {
            self.bestLabel.setTextColor(UIColor(named: .Record))
         }
      }
   }

   @IBOutlet private weak var bestLabel: WKInterfaceLabel!
   @IBOutlet private weak var countLabel: WKInterfaceLabel!
   @IBOutlet private weak var durationLabel: WKInterfaceLabel!

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      guard let contexts = context as? [AnyObject] else {
         return
      }

      self.interval = contexts.flatMap { $0 as? Interval }.first
      self.delegate = contexts.flatMap { $0 as? IntervalInterfaceControllerDelegate }.first
   }

   override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }

   @IBAction private func deleteAction() {
      let cancelAction = WKAlertAction(title: tr(.Cancel), style: .Cancel) {}

      let deleteAction = WKAlertAction(title: tr(.Delete), style: .Destructive) {
         [unowned self] in
         self.delegate?.deleteIntervalInterfaceController(self)

      }

      self.presentAlertControllerWithTitle(tr(.DeleteIntervalTitle),
         message: nil,
         preferredStyle: .Alert,
         actions: [cancelAction, deleteAction])
   }

   @IBAction private func sendAction() {
      ServerSynchronizer.defaultServer.synchronizeInterval(self.interval)
   }
}
