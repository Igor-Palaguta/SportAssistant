import WatchKit
import Foundation
import HealthKit
import watchOSEngine

class MenuInterfaceController: WKInterfaceController {

   @IBOutlet private weak var bestLabel: WKInterfaceLabel!
   @IBOutlet private weak var trainingsButton: WKInterfaceButton!

   private lazy var healthStore = HKHealthStore()
   private var didActivateBefore = false

   override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()

      guard !self.didActivateBefore else {
         return
      }

      self.reloadData()

      self.healthStore.requestAuthorizationToShareTypes(Set([HKObjectType.workoutType()]),
         readTypes: Set([HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!])) {
            success, error in
            if let error = error {
               NSLog("requestAuthorizationToShareTypes: %@", error)
            }
      }

      self.didActivateBefore = true
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
      switch segueIdentifier {
      case String(RecordTrainingInterfaceController.self):
         return TrainingContext(healthStore: self.healthStore, tag: nil)
      case String(TagsInterfaceController.self):
         return self.healthStore
      default:
         return nil
      }
   }

   private func reloadData() {
      let storage = StorageController.UIController
      self.trainingsButton.setTitle(tr(.TrainingsCountFormat(storage.trainingsCount)))
      self.bestLabel.setText(tr(.RecordFormat(storage.best.formattedAcceleration)))
   }
}
