import Foundation
import CoreMotion

protocol AccelerometerData {
   var x: Double { get }
   var y: Double { get }
   var z: Double { get }
   var date: NSDate { get }
}

protocol MotionManager: class {
   var accelerometerUpdateInterval: NSTimeInterval { get set }

   func startWithHandler(handler: (AccelerometerData) -> ())
   func stop()
}

extension CMAccelerometerData: AccelerometerData {

   var x: Double {
      return self.acceleration.x
   }

   var y: Double {
      return self.acceleration.y
   }

   var z: Double {
      return self.acceleration.z
   }

   var date: NSDate {
      let bootTime = NSDate(timeIntervalSinceNow: -NSProcessInfo.processInfo().systemUptime)
      let date = NSDate(timeInterval: self.timestamp, sinceDate: bootTime)
      return date
   }
}

extension CMMotionManager: MotionManager {

   func startWithHandler(handler: (AccelerometerData) -> ()) {
      if !self.accelerometerAvailable {
         return
      }
      self.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) {
         data, _ in
         if let data = data {
            handler(data)
         }
      }
   }

   func stop() {
      self.stopAccelerometerUpdates()
   }
}

private struct SimulatedAccelerometerDate: AccelerometerData {
   let x: Double
   let y: Double
   let z: Double
   let date: NSDate
}

class AccelerometerSimulator: MotionManager {

   var accelerometerUpdateInterval: NSTimeInterval = 0.1

   private weak var timer: NSTimer?

   private class FireContext {
      let start = NSDate()
      let handler: (AccelerometerData) -> ()

      init(handler: (AccelerometerData) -> ()) {
         self.handler = handler
      }
   }

   func startWithHandler(handler: (AccelerometerData) -> ()) {
      if let timer = self.timer {
         timer.invalidate()
      }

      self.timer = NSTimer.scheduledTimerWithTimeInterval(self.accelerometerUpdateInterval,
         target: self,
         selector: Selector("generateAcceleration:"),
         userInfo: FireContext(handler: handler),
         repeats: true)
   }

   func stop() {
      self.timer?.invalidate()
      self.timer = nil
   }

   @objc private func generateAcceleration(timer: NSTimer) {
      guard let context = timer.userInfo as? FireContext else {
         return
      }

      let eventDate = NSDate()
      let timestamp = eventDate.timeIntervalSinceDate(context.start)

      let randomFactor = Double(arc4random()) / Double(UID_MAX)

      let accelerationData = SimulatedAccelerometerDate(x: randomFactor * 12 * sin(timestamp * M_PI),
         y: randomFactor * 4 * cos(timestamp * M_PI_2),
         z: randomFactor * sin(timestamp + M_PI_2),
         date: eventDate)
      
      context.handler(accelerationData)
   }
}
