import WatchKit
import Foundation
import HealthKit

class MenuInterfaceController: WKInterfaceController {

   private lazy var healthStore = HKHealthStore()

   @IBOutlet private weak var bestLabel: WKInterfaceLabel!

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      // Configure interface objects here.
   }

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
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }

   override func didAppear() {
      super.didAppear()

      let historyController = HistoryController()
      self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(historyController.best))
   }

   override func contextForSegueWithIdentifier(segueIdentifier: String) -> AnyObject? {
      if segueIdentifier == String(TrainingInterfaceController.self) {
         return self.healthStore
      }
      return nil
   }
}
