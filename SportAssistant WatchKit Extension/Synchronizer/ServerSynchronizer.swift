import Foundation
import WatchConnectivity

final class ServerSynchronizer: NSObject {

   static let defaultServer = ServerSynchronizer()

   private lazy var session: WCSession? = {
      if WCSession.isSupported() {
         let session = WCSession.defaultSession()
         session.delegate = self
         session.activateSession()
         return session
      }
      return nil
   }()

   func sendPackage(package: Package) {
      let message = package.toMessage()
      NSLog("sendPackage: %@", message)
      self.session!.transferUserInfo(message)
   }
}

extension ServerSynchronizer: WCSessionDelegate {
   func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {
      NSLog("didFinishUserInfoTransfer: %@", error?.localizedDescription ?? "success")
   }
}
