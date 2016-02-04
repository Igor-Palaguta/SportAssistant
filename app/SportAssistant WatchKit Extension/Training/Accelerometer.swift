import Foundation
import CoreMotion

protocol AccelerometerDelegate: class {
   func accelerometer(accelerometer: Accelerometer, didReceiveData data: AccelerometerData)
}

class Accelerometer {

   weak var delegate: AccelerometerDelegate?

   private var manager: MotionManager?

   deinit {
      self.stop()
   }

   func start() {
      self.stop()

      let manager: MotionManager = NSProcessInfo.processInfo().isSimulator
         ? AccelerometerSimulator()
         : CMMotionManager()

      manager.accelerometerUpdateInterval = 0.1

      manager.startWithHandler {
         [weak self] data in
         if let strongSelf = self {
            strongSelf.delegate?.accelerometer(strongSelf, didReceiveData: data)
         }
      }

      self.manager = manager
   }

   func stop() {
      self.manager?.stop()
   }
}

