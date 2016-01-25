import Foundation
import RealmSwift

extension Realm {
   class func configure() {
      var config = Realm.Configuration()

      let documentsURL = NSFileManager.defaultManager()
         .URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
         .first!

      config.path = documentsURL
         .URLByAppendingPathComponent("Acceleration.realm")
         .path

      Realm.Configuration.defaultConfiguration = config
   }

   class func write(@noescape transaction: (Realm) -> ()) {
      if let realm = try? Realm() {
         do {
            try realm.write {
               transaction(realm)
            }
         } catch {
         }
      }
   }
}
