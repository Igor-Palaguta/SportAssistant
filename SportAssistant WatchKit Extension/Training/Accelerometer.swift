import Foundation
import CoreMotion

protocol AccelerometerDelegate: class {
   func accelerometer(accelerometer: Accelerometer, didReceiveData data: AccelerometerData)
}

struct AccelerometerData {
   let x: Double
   let y: Double
   let z: Double
}

extension AccelerometerData {
   func toDictionary() -> [String: AnyObject] {
      return ["x": x, "y": y, "z": z]
   }
}

class Accelerometer {

   weak var delegate: AccelerometerDelegate?

   private var manager: CMMotionManager?
   private var semaphore: dispatch_semaphore_t?

   deinit {
      self.stop()
   }

   func start() {
      self.stop()

      let semaphore = dispatch_semaphore_create(0)

      NSProcessInfo.processInfo().performExpiringActivityWithReason("Training") {
         expired in
         if !expired {
            NSLog("b performExpiringActivityWithReason not expired")
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(300 * Double(NSEC_PER_SEC)))
            dispatch_semaphore_wait(semaphore, delayTime)
            NSLog("a performExpiringActivityWithReason not expired")
         } else {
            NSLog("b performExpiringActivityWithReason expired")
            dispatch_semaphore_signal(semaphore)
            NSLog("a performExpiringActivityWithReason expired")
         }
      }

      let manager = CMMotionManager()
      manager.accelerometerUpdateInterval = 0.5

      if manager.accelerometerAvailable {
         manager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) {
            [weak self] data, error in
            guard let strongSelf = self else {
               return
            }

            if let data = data {
               let acceleratorData = AccelerometerData(x: data.acceleration.x,
                  y: data.acceleration.y,
                  z: data.acceleration.z)
               strongSelf.delegate?.accelerometer(strongSelf, didReceiveData: acceleratorData)
            } else if let error = error {
               print("startAccelerometerUpdatesToQueue: \(error)")
            }
         }
      }

      self.manager = manager
      self.semaphore = semaphore
   }

   func stop() {
      self.manager?.stopAccelerometerUpdates()
      if let semaphore = self.semaphore {
         NSLog("stop")
         dispatch_semaphore_signal(semaphore)
         self.semaphore = nil
      }
   }
}
