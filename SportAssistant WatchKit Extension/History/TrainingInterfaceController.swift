import WatchKit
import Foundation

protocol TrainingInterfaceControllerDelegate: class {
   func deleteTrainingInterfaceController(controller: TrainingInterfaceController)
}

final class TrainingInterfaceController: WKInterfaceController {

   private weak var delegate: TrainingInterfaceControllerDelegate?

   private(set) var training: Training! {
      didSet {
         self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(training.best))
         self.durationLabel.setDuration(training.duration)
         self.countLabel.setText(training.activities.count.description)
         if training.best == HistoryController.mainThreadController.best {
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

      self.training = contexts.flatMap { $0 as? Training }.first
      self.delegate = contexts.flatMap { $0 as? TrainingInterfaceControllerDelegate }.first
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
         self.delegate?.deleteTrainingInterfaceController(self)
      }

      self.presentAlertControllerWithTitle(tr(.DeleteTrainingTitle),
         message: nil,
         preferredStyle: .SideBySideButtonsAlert,
         actions: [cancelAction, deleteAction])
   }

   @IBAction private func sendAction() {
      ServerSynchronizer.defaultServer.synchronizeTraining(self.training)
   }
}
