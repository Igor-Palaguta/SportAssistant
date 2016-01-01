import Foundation

class BackgroundSuspender {

   private var semaphore: dispatch_semaphore_t?

   func suspend() {
      self.stop()

      let semaphore = dispatch_semaphore_create(0)

      NSProcessInfo.processInfo().performExpiringActivityWithReason(String(Accelerometer)) {
         expired in
         if !expired {
            let delay: Int64 = 5 * 60
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, delay * Int64(NSEC_PER_SEC))
            dispatch_semaphore_wait(semaphore, delayTime)
         } else {
            dispatch_semaphore_signal(semaphore)
         }
      }

      self.semaphore = semaphore
   }

   func stop() {
      if let semaphore = self.semaphore {
         dispatch_semaphore_signal(semaphore)
         self.semaphore = nil
      }
   }
}
