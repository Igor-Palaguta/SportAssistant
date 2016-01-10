import WatchKit
import Foundation
import CoreMotion
import HealthKit

private class Session: NSObject {

   let interval: Interval
   let accelerometer: Accelerometer
   let suspender = BackgroundSuspender()
   let analyzer = TableTennisAnalyzer()

   let workoutSession: HKWorkoutSession
   let healthStore: HKHealthStore

   init(healthStore: HKHealthStore) {
      let interval = Interval()
      HistoryController.mainThreadController.addInterval(interval)
      self.interval = interval
      self.accelerometer = Accelerometer()
      self.accelerometer.start()
      self.healthStore = healthStore
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

final class TrainingInterfaceController: WKInterfaceController {

   @IBOutlet weak var bestLabel: WKInterfaceLabel!
   @IBOutlet weak var lastLabel: WKInterfaceLabel!
   @IBOutlet weak var durationLabel: WKInterfaceLabel!
   @IBOutlet weak var startButton: WKInterfaceButton!

   private var recordSession: Session?
   private var healthStore: HKHealthStore?

   private func stopRecording() {
      if let recordSession = self.recordSession {
         let outstandingData = recordSession.analyzer.outstandingData

         if !outstandingData.isEmpty {
            ServerSynchronizer.defaultServer.sendData(outstandingData, forInterval: recordSession.interval)
         }

         ServerSynchronizer.defaultServer.stopInterval(recordSession.interval)

         recordSession.stop()
         self.recordSession = nil

         self.startButton.setBackgroundColor(UIColor(named: .Base))
         self.startButton.setTitle(tr(.Start))
      }
   }

   private func startRecording() {
      if self.recordSession == nil {

         self.lastLabel.setText("-")
         self.durationLabel.setText(0.toDurationString())

         self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(0))
         self.bestLabel.setTextColor(UIColor.whiteColor())

         let recordSession = Session(healthStore: self.healthStore!)
         recordSession.accelerometer.delegate = self
         self.recordSession = recordSession
         ServerSynchronizer.defaultServer.startInterval(recordSession.interval)

         self.startButton.setBackgroundColor(UIColor(named: .Destructive))
         self.startButton.setTitle(tr(.Stop))
      }
   }

   private func reloadDataWithTotal(total: Double, last: Double?, duration: Double?, playHaptic: Bool = false) {
      guard let recordSession = self.recordSession else {
         return
      }

      if let last = last {
         self.lastLabel.setText(NSNumberFormatter.stringForAcceleration(last))
      }

      if let duration = duration {
         self.durationLabel.setText(duration.toDurationString())
      }

      if total < recordSession.interval.best {
         return
      }

      self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(total))

      if total < HistoryController.mainThreadController.best {
         return
      }

      self.bestLabel.setTextColor(UIColor(named: .Record))

      if playHaptic {
         WKInterfaceDevice.currentDevice().playHaptic(.Success)
      }
   }

   override func willActivate() {
      super.willActivate()
      if let recordSession = self.recordSession {
         recordSession.suspender.suspend()

         self.reloadDataWithTotal(recordSession.interval.best,
            last: recordSession.interval.activitiesData.last?.total,
            duration: recordSession.interval.data.last?.timestamp)
      }
   }

   override func willDisappear() {
      super.willDisappear()
      self.stopRecording()
   }

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      self.healthStore = context as? HKHealthStore

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

extension TrainingInterfaceController: AccelerometerDelegate {
   func accelerometer(accelerometer: Accelerometer, didReceiveData data: CMAccelerometerData) {
      guard let recordSession = self.recordSession else {
         return
      }

      let bootTime = NSDate(timeIntervalSinceNow: -NSProcessInfo.processInfo().systemUptime)
      let date = NSDate(timeInterval: data.timestamp, sinceDate: bootTime)

      let accelerationData = AccelerationData(x: data.acceleration.x,
         y: data.acceleration.y,
         z: data.acceleration.z,
         timestamp: date.timeIntervalSinceDate(recordSession.interval.start))

      let result = recordSession.analyzer.analyzeData(accelerationData)
      self.reloadDataWithTotal(accelerationData.total,
         last: result.peak?.data.total,
         duration: accelerationData.timestamp,
         playHaptic: true)

      HistoryController.mainThreadController.appendDataFromArray([accelerationData], toInterval: recordSession.interval)

      if let peak = result.peak {
         HistoryController.mainThreadController.addActivityWithName(peak.attributes.description,
            toData: peak.data)
      }

      if !result.data.isEmpty {
         ServerSynchronizer.defaultServer.sendData(result.data, forInterval: recordSession.interval)
      }
   }
}
