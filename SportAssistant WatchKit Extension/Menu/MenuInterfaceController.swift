import WatchKit
import Foundation
import WatchConnectivity

class MenuInterfaceController: WKInterfaceController {

   private lazy var session: WCSession? = {
      if WCSession.isSupported() {
         let session = WCSession.defaultSession()
         session.delegate = self
         session.activateSession()
         return session
      }
      return nil
   }()

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      // Configure interface objects here.
   }

   override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }

   override func contextForSegueWithIdentifier(segueIdentifier: String) -> AnyObject? {
      if segueIdentifier == String(TrainingInterfaceController.self) {
         return self
      }
      return nil
   }
}

extension MenuInterfaceController: TrainingInterfaceControllerDelegate {
   func trainingInterfaceController(controller: TrainingInterfaceController, didReceiveAccelerometerData data: AccelerometerData) {
      self.session?.transferUserInfo(["acceleration": data.toDictionary()])
   }
}

extension MenuInterfaceController: WCSessionDelegate {
   func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {
      print("didFinishUserInfoTransfer \(userInfoTransfer)")
   }
}
