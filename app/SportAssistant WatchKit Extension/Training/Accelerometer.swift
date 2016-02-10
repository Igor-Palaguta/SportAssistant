import Foundation
import CoreMotion

protocol AccelerometerDelegate: class {
   func accelerometer(accelerometer: Accelerometer, didReceiveData data: AccelerometerData)
}

private class AccelerometerDataBuffer: AccelerometerData {
   let date: NSDate
   var count: Int = 1

   var x: Double {
      return self.max.x
   }

   var y: Double {
      return self.max.y
   }

   var z: Double {
      return self.max.z
   }

   var max: AccelerometerData

   init(data: AccelerometerData) {
      self.date = data.date
      self.max = data
   }

   func addData(data: AccelerometerData) {
      count += 1
      if self.max < data {
         self.max = data
      }
   }
}

class Accelerometer {

   weak var delegate: AccelerometerDelegate?

   private var manager: MotionManager?
   private var updateInterval: NSTimeInterval = 0.1
   private var buffer: AccelerometerDataBuffer?

   deinit {
      self.stop()
   }

   func start() {
      self.stop()

      let manager: MotionManager = NSProcessInfo.processInfo().isSimulator
         ? AccelerometerSimulator()
         : CMMotionManager()

      manager.accelerometerUpdateInterval = 0.01

      manager.startWithHandler {
         [weak self] data in
         guard let strongSelf = self else {
            return
         }

         guard let buffer = strongSelf.buffer else {
            strongSelf.buffer = AccelerometerDataBuffer(data: data)
            return
         }

         if data.date.timeIntervalSinceDate(buffer.date) <= strongSelf.updateInterval {
            buffer.addData(data)
         } else {
            strongSelf.delegate?.accelerometer(strongSelf, didReceiveData: buffer)
            strongSelf.buffer = AccelerometerDataBuffer(data: data)
         }
      }

      self.manager = manager
   }

   func stop() {
      self.buffer = nil
      self.manager?.stop()
   }
}

