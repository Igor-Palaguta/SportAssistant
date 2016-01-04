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

class TrainingInterfaceController: WKInterfaceController {

   @IBOutlet weak var bestLabel: WKInterfaceLabel!

   private var recordSession: Session?
   private var healthStore: HKHealthStore?

   private func stopRecording() {
      if let recordSession = self.recordSession {
         let outstandingData = recordSession.analyzer.outstandingData

         if !outstandingData.isEmpty {
            ServerSynchronizer.defaultServer.sendPackage(.Data(recordSession.interval.id, outstandingData))
         }

         ServerSynchronizer.defaultServer.sendPackage(.Stop(recordSession.interval.id))
         recordSession.stop()
         self.recordSession = nil
      }
   }

   private func startRecording() {
      if self.recordSession == nil {
         let recordSession = Session(healthStore: self.healthStore!)
         recordSession.accelerometer.delegate = self
         self.recordSession = recordSession
         ServerSynchronizer.defaultServer.sendPackage(.Start(recordSession.interval.id, recordSession.interval.start))
      }
   }

   override func willActivate() {
      super.willActivate()
      if let recordSession = self.recordSession {
         recordSession.suspender.suspend()
         self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(recordSession.interval.best))

         if recordSession.interval.best == HistoryController.mainThreadController.best {
            self.bestLabel.setTextColor(.greenColor())
         }
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

   @IBAction private func stopAction(_: WKInterfaceButton) {
      self.stopRecording()
      self.dismissController()
   }

   @IBAction private func restartAction(_: WKInterfaceButton) {
      self.stopRecording()
      self.startRecording()
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
      //NSLog("data[%@]: %@",
      //   recordSession.interval.data.count.description,
      //   accelerationData.total.description)

      if accelerationData.total > recordSession.interval.best {
         self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(accelerationData.total))
      }

      let historyController = HistoryController()

      if accelerationData.total > historyController.best {
         WKInterfaceDevice.currentDevice().playHaptic(.Success)
         self.bestLabel.setTextColor(.greenColor())
      }

      let result = recordSession.analyzer.analyzeData(accelerationData)

      historyController.addData([accelerationData], toInterval: recordSession.interval)

      if let peak = result.peak {
         historyController.addActivityWithName(peak.attributes.description,
            toData: peak.data)
      }

      if !result.data.isEmpty {
         ServerSynchronizer.defaultServer.sendPackage(.Data(recordSession.interval.id, result.data))
      }
   }
}
