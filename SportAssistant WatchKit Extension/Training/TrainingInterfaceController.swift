import WatchKit
import Foundation
import RealmSwift
import CoreMotion

class TrainingInterfaceController: WKInterfaceController {

   @IBOutlet weak var bestLabel: WKInterfaceLabel!

   private var suspender: BackgroundSuspender?
   private var interval: Interval?

   private lazy var accelerometer: Accelerometer = {
      [unowned self] in
      let accelerometer = Accelerometer()
      accelerometer.delegate = self
      return accelerometer
      }()

   private func stopRecording() {
      if let interval = self.interval {
         ServerSynchronizer.defaultServer.sendPackage(.Stop(interval.id))
      }
      self.interval = nil
      self.accelerometer.stop()
      self.suspender?.stop()
      self.suspender = nil
   }

   private func startRecording() {
      let interval = Interval()
      Realm.write {
         realm in
         realm.currentHistory.addInterval(interval)
      }
      self.interval = interval
      ServerSynchronizer.defaultServer.sendPackage(.Start(interval.id))

      self.accelerometer.start()
      self.suspender = BackgroundSuspender()
      self.suspender?.suspend()
   }

   override func willActivate() {
      super.willActivate()
      self.suspender?.suspend()

      if let interval = self.interval {
         self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(interval.best))

         if interval.best == interval.history.best {
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
      guard let interval = self.interval else {
         return
      }

      let accelerationData = AccelerationData(x: data.acceleration.x,
         y: data.acceleration.y,
         z: data.acceleration.z,
         date: NSDate())

      ServerSynchronizer.defaultServer.sendPackage(.Data(interval.id, [accelerationData]))

      if accelerationData.total > interval.best {
         self.bestLabel.setText(NSNumberFormatter.stringForAcceleration(accelerationData.total))
      }

      if accelerationData.total > interval.history.best {
         WKInterfaceDevice.currentDevice().playHaptic(.Success)
         self.bestLabel.setTextColor(.greenColor())
      }

      Realm.write {
         realm in
         interval.history.addData(accelerationData, toInterval: interval)
      }

   }
}
