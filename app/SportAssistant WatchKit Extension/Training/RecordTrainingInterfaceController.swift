import WatchKit
import Foundation
import CoreMotion
import HealthKit

private class Session: NSObject {

   let training: Training
   let accelerometer: Accelerometer
   let suspender = BackgroundSuspender()
   let analyzer = TableTennisAnalyzer()

   let workoutSession: HKWorkoutSession
   let healthStore: HKHealthStore

   init(context: TrainingContext) {
      let training = StorageController.UIController.createTraining(context.tag)
      self.training = training
      self.accelerometer = Accelerometer()
      self.accelerometer.start()
      self.healthStore = context.healthStore
      self.workoutSession = HKWorkoutSession(activityType: .TableTennis, locationType: .Indoor)
      super.init()
      self.workoutSession.delegate = self
      self.healthStore.startWorkoutSession(self.workoutSession)
   }

   func stop() {
      self.accelerometer.stop()
      self.suspender.stop()
      self.healthStore.endWorkoutSession(self.workoutSession)
   }
}

extension Session: HKWorkoutSessionDelegate {
   @objc private func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
      NSLog("didChangeToState %d", toState.rawValue)
   }

   @objc private func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
      NSLog("didFailWithError %@", error)
   }
}

final class TrainingContext {
   let healthStore: HKHealthStore
   let tag: Tag?

   init(healthStore: HKHealthStore, tag: Tag? = nil) {
      self.healthStore = healthStore
      self.tag = tag
   }
}

final class RecordTrainingInterfaceController: WKInterfaceController {

   @IBOutlet weak var bestLabel: WKInterfaceLabel!
   @IBOutlet weak var lastLabel: WKInterfaceLabel!
   @IBOutlet weak var durationLabel: WKInterfaceLabel!
   @IBOutlet weak var startButton: WKInterfaceButton!

   private var recordSession: Session?
   private var context: TrainingContext!

   private func stopRecording() {
      if let recordSession = self.recordSession {
         WKInterfaceDevice.currentDevice().playHaptic(.Stop)

         let outstandingData = recordSession.analyzer.outstandingData

         if !outstandingData.isEmpty {
            ServerSynchronizer.defaultServer.sendData(outstandingData, forTraining: recordSession.training)
         }

         ServerSynchronizer.defaultServer.stopTraining(recordSession.training)

         recordSession.stop()
         self.recordSession = nil

         self.animateWithDuration(0.3) {
            self.startButton.setBackgroundColor(UIColor(named: .Base))
            self.startButton.setTitle(tr(.Start))
         }

         self.durationLabel.stop()
      }
   }

   private func startRecording() {
      if self.recordSession == nil {
         WKInterfaceDevice.currentDevice().playHaptic(.Start)

         self.lastLabel.setText("-")

         self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(0))
         self.bestLabel.setTextColor(.whiteColor())

         let recordSession = Session(context: self.context)
         recordSession.accelerometer.delegate = self
         self.recordSession = recordSession
         ServerSynchronizer.defaultServer.startTraining(recordSession.training)
         self.durationLabel.start(recordSession.training.start)

         var userInfo = ["id": recordSession.training.id, "start": recordSession.training.start]
         if let tag = self.context.tag {
            userInfo["tag"] = tag.id
         }

         self.updateUserActivity("com.spangleapp.Test.watchkitapp.watchkitextension.Training",
            userInfo: userInfo,
            webpageURL: nil)

         self.animateWithDuration(0.3) {
            self.startButton.setBackgroundColor(UIColor(named: .Destructive))
            self.startButton.setTitle(tr(.Stop))
         }
      }
   }

   private func reloadDataWithTotal(total: Double, last: Double?, duration: Double?, playHaptic: Bool = false) {
      guard let recordSession = self.recordSession else {
         return
      }

      if let last = last {
         self.lastLabel.setText(NSNumberFormatter.stringForAcceleration(last))
      }

      //if let duration = duration {
      //   self.durationLabel.setText(duration.toDurationString())
      //}

      if total < recordSession.training.best {
         return
      }

      self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(total))

      if total < StorageController.UIController.best {
         return
      }

      self.bestLabel.setTextColor(UIColor(named: .Record))

      if playHaptic {
         WKInterfaceDevice.currentDevice().playHaptic(.DirectionUp)
      }
   }

   override func willActivate() {
      super.willActivate()
      if let recordSession = self.recordSession {
         recordSession.suspender.suspend()

         self.reloadDataWithTotal(recordSession.training.best,
            last: recordSession.training.activitiesData.last?.total,
            duration: recordSession.training.data.last?.timestamp)

         self.durationLabel.start(recordSession.training.start)
      }
   }

   override func willDisappear() {
      super.willDisappear()
      self.stopRecording()
      self.durationLabel.stop()
      self.invalidateUserActivity()
   }

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      self.context = context as! TrainingContext
      self.setTitle(self.context.tag?.name ?? tr(.Other))

      self.startRecording()
   }

   @IBAction private func toggleStartAction(_: WKInterfaceButton) {
      if self.recordSession == nil {
         self.startRecording()
      } else {
         self.stopRecording()
      }
   }
}

extension RecordTrainingInterfaceController: AccelerometerDelegate {
   func accelerometer(accelerometer: Accelerometer, didReceiveData data: CMAccelerometerData) {
      guard let recordSession = self.recordSession else {
         return
      }

      let bootTime = NSDate(timeIntervalSinceNow: -NSProcessInfo.processInfo().systemUptime)
      let date = NSDate(timeInterval: data.timestamp, sinceDate: bootTime)

      let accelerationData = AccelerationData(x: data.acceleration.x,
         y: data.acceleration.y,
         z: data.acceleration.z,
         timestamp: date.timeIntervalSinceDate(recordSession.training.start))

      let result = recordSession.analyzer.analyzeData(accelerationData)
      self.reloadDataWithTotal(accelerationData.total,
         last: result.peak?.data.total,
         duration: accelerationData.timestamp,
         playHaptic: true)

      StorageController.UIController.appendDataFromArray([accelerationData], toTraining: recordSession.training)

      if let peak = result.peak {
         StorageController.UIController.addActivityWithName(peak.attributes.description,
            toData: peak.data)
      }

      if !result.data.isEmpty {
         ServerSynchronizer.defaultServer.sendData(result.data, forTraining: recordSession.training)
      }
   }
}
