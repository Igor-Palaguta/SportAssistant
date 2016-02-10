import WatchKit
import Foundation
import watchOSEngine

protocol TrainingInterfaceControllerDelegate: class {
   func deleteTrainingInterfaceController(controller: TrainingInterfaceController)
}

final class TrainingInterfaceController: WKInterfaceController {

   @IBOutlet private weak var tagsLabel: WKInterfaceLabel!
   @IBOutlet private weak var bestLabel: WKInterfaceLabel!
   @IBOutlet private weak var countLabel: WKInterfaceLabel!
   @IBOutlet private weak var durationLabel: WKInterfaceLabel!
   @IBOutlet private weak var averageLabel: WKInterfaceLabel!
   @IBOutlet private weak var minimumLabel: WKInterfaceLabel!

   private weak var delegate: TrainingInterfaceControllerDelegate?

   private(set) var training: Training! {
      didSet {
         let tagsString = training.tags.map { $0.name }.joinWithSeparator(", ")
         self.tagsLabel.setText(tagsString)
         self.bestLabel.setText(training.best.formattedAcceleration)
         self.durationLabel.setDuration(training.duration)
         let activityEvents = training.activityEvents
         self.countLabel.setText("\(activityEvents.count)")
         self.averageLabel.setText(training.average?.formattedAcceleration)
         self.minimumLabel.setText(training.minimum?.formattedAcceleration)
         if training.best == StorageController.UIController.best {
            self.bestLabel.setTextColor(UIColor(named: .Record))
         }
      }
   }

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      guard let contexts = context as? [AnyObject] else {
         return
      }

      self.training = contexts.flatMap { $0 as? Training }.first
      self.delegate = contexts.flatMap { $0 as? TrainingInterfaceControllerDelegate }.first
   }

   override func didAppear() {
      super.didAppear()

      if !self.training.invalidated {
         self.updateUserActivity(NSUserActivity.trainingType,
            userInfo: self.training.userActivityInfo,
            webpageURL: nil)
      }
   }

   override func willDisappear() {
      super.willDisappear()

      self.invalidateUserActivity()
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
