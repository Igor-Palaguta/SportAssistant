import Foundation
import CoreMotion

protocol AccelerometerDelegate: class {
   func accelerometer(accelerometer: Accelerometer, didReceiveData data: BaseAccelerationData)
}

extension CMAccelerometerData: BaseAccelerationData {
   var date: NSDate! {
      let bootTime = NSDate(timeIntervalSinceNow: NSProcessInfo.processInfo().systemUptime)
      return NSDate(timeInterval: self.timestamp, sinceDate: bootTime)
   }

   var x: Double {
      return self.acceleration.x
   }

   var y: Double {
      return self.acceleration.y
   }

   var z: Double {
      return self.acceleration.z
   }

   var total: Double {
      return sqrt(x*x + y*y + z*z)
   }
}

class Accelerometer {

   weak var delegate: AccelerometerDelegate?

   private var manager: CMMotionManager?

   deinit {
      self.stop()
   }

   func start() {
      self.stop()

      let manager = CMMotionManager()
      manager.accelerometerUpdateInterval = 0.2

      if manager.accelerometerAvailable {
         manager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) {
            [weak self] data, error in
            guard let strongSelf = self else {
               return
            }

            if let data = data {
               strongSelf.delegate?.accelerometer(strongSelf, didReceiveData: data)
            } else if let error = error {
               print("startAccelerometerUpdatesToQueue: \(error)")
            }
         }
      }

      self.manager = manager
   }

   func stop() {
      self.manager?.stopAccelerometerUpdates()
   }
}
