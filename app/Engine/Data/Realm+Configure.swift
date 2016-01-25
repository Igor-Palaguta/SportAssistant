import Foundation
import RealmSwift

extension Realm {
   public class func configure() {
      var config = Realm.Configuration()

      let documentsURL = NSFileManager.defaultManager()
         .URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
         .first!

      config.path = documentsURL
         .URLByAppendingPathComponent("Acceleration.realm")
         .path

      Realm.Configuration.defaultConfiguration = config
   }
}
