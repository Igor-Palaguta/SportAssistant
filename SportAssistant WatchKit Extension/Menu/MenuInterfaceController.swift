import WatchKit
import Foundation
import HealthKit

class MenuInterfaceController: WKInterfaceController {

   private lazy var healthStore = HKHealthStore()

   @IBOutlet private weak var bestLabel: WKInterfaceLabel!
   @IBOutlet private weak var trainingsButton: WKInterfaceButton!

   override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()

      self.healthStore.requestAuthorizationToShareTypes(Set([HKObjectType.workoutType()]),
         readTypes: Set([HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!])) {
            success, error in
            if let error = error {
               NSLog("requestAuthorizationToShareTypes: %@", error)
            }
      }

      self.reloadData()
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }

   override func didAppear() {
      super.didAppear()

      self.reloadData()
   }

   override func contextForSegueWithIdentifier(segueIdentifier: String) -> AnyObject? {
      if segueIdentifier == String(TrainingInterfaceController.self) {
         return self.healthStore
      }
      return nil
   }

   private func reloadData() {
      let historyController = HistoryController.mainThreadController
      self.trainingsButton.setTitle(tr(.TrainingsCountFormat(historyController.intervals.count)))
      self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(historyController.best))
   }
}
