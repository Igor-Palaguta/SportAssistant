import WatchKit
import Foundation
import RealmSwift
import CoreMotion

class TrainingInterfaceController: WKInterfaceController {

   @IBOutlet weak var countLabel: WKInterfaceLabel!
   @IBOutlet weak var bestLabel: WKInterfaceLabel!
   @IBOutlet weak var worstLabel: WKInterfaceLabel!
   @IBOutlet weak var averageLabel: WKInterfaceLabel!

   private var suspender: BackgroundSuspender?
   private var interval: Interval?

   private lazy var accelerometer: Accelerometer = {
      [unowned self] in
      let accelerometer = Accelerometer()
      accelerometer.delegate = self
      return accelerometer
      }()

   deinit {
      self.suspender?.stop()
   }

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

   override func didDeactivate() {
      super.didDeactivate()
   }

   override func willActivate() {
      super.willActivate()
      self.suspender?.suspend()
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

      Realm.write {
         realm in
         if let history = realm.objects(History.self).first {
            history.addData(accelerationData, toInterval: interval)
         }
      }

      self.bestLabel.setText(NSNumberFormatter.formatAccelereration(interval.best))
   }
}
