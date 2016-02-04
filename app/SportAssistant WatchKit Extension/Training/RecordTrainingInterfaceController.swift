import WatchKit
import Foundation
import CoreMotion
import HealthKit
import watchOSEngine

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
      let activityType = context.tag?.activityType ?? HKWorkoutActivityType.Other
      self.workoutSession = HKWorkoutSession(activityType: activityType, locationType: .Indoor)
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

         let outstandingEvents = recordSession.analyzer.outstandingEvents

         if !outstandingEvents.isEmpty {
            ServerSynchronizer.defaultServer.sendEvents(outstandingEvents, forTraining: recordSession.training)
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

         self.updateUserActivity(NSUserActivity.trainingType,
            userInfo: recordSession.training.userActivityInfo,
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
         self.lastLabel.setText(last.formattedAcceleration)
      }

      //if let duration = duration {
      //   self.durationLabel.setText(duration.toDurationString())
      //}

      if total < recordSession.training.best {
         return
      }

      self.bestLabel.setText(total.formattedAcceleration)

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
            last: recordSession.training.activityEvents.last?.total,
            duration: recordSession.training.events.last?.timestamp)

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
      self.setTitle(self.context.tag?.name)

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
   func accelerometer(accelerometer: Accelerometer, didReceiveData data: AccelerometerData) {
      guard let recordSession = self.recordSession else {
         return
      }

      let event = AccelerationEvent(x: data.x,
         y: data.y,
         z: data.z,
         timestamp: data.date.timeIntervalSinceDate(recordSession.training.start))

      let result = recordSession.analyzer.analyzeEvent(event)
      self.reloadDataWithTotal(event.total,
         last: result.peak?.event.total,
         duration: event.timestamp,
         playHaptic: true)

      StorageController.UIController.appendEvents([event], toTraining: recordSession.training)

      if let peak = result.peak {
         StorageController.UIController.addActivityWithName(peak.attributes.description,
            toEvent: peak.event)
      }

      if !result.events.isEmpty {
         ServerSynchronizer.defaultServer.sendEvents(result.events, forTraining: recordSession.training)
      }
   }
}
