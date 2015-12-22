import Foundation
import CoreMotion

final class AccelerationData: NSObject, BaseAccelerationData {

   let attributes: [String: AnyObject]

   var date: NSDate! {
      return self.attributes["date"] as! NSDate
   }

   var x: Double {
      return self.attributes["x"] as! Double
   }

   var y: Double {
      return self.attributes["y"] as! Double
   }

   var z: Double {
      return self.attributes["z"] as! Double
   }

   var total: Double {
      return self.attributes["total"] as! Double
   }

   init(data: BaseAccelerationData) {
      self.attributes = ["x": data.x,
         "y": data.y,
         "z": data.z,
         "total": data.total,
         "date": data.date]
      super.init()
   }

   func encodeWithCoder(aCoder: NSCoder) {
      aCoder.encodeObject(self.attributes, forKey: "attributes")
   }

   required init?(coder aDecoder: NSCoder) {
      self.attributes = aDecoder.decodeObjectForKey("attributes") as! [String: AnyObject]
      super.init()
   }
}

final class Training: NSObject, NSCoding {
   private(set) var id = NSUUID().UUIDString
   private var data: [AccelerationData] = []
   var best: Double = 0
   var start: NSDate {
      return self.data.first!.date
   }

   override init() {
      super.init()
   }

   func encodeWithCoder(aCoder: NSCoder) {
      aCoder.encodeObject(self.id, forKey: "id")
      aCoder.encodeObject(self.data, forKey: "data")
      aCoder.encodeDouble(self.best, forKey: "best")
   }

   required init?(coder aDecoder: NSCoder) {
      self.id = aDecoder.decodeObjectForKey("id") as! String
      self.data = aDecoder.decodeObjectForKey("data") as! [AccelerationData]
      self.best = aDecoder.decodeDoubleForKey("best")
      super.init()
   }

   private func addData(data: AccelerationData) {
      if data.total > self.best {
         self.best = data.total
      }
      self.data.append(data)
   }
}

final class History {
   private(set) lazy var trainings: [Training] = {
      [unowned self] in
      if let archive = NSKeyedUnarchiver.unarchiveObjectWithFile(self.archiveURL.absoluteString) as? [Training] {
         return archive
      }
      return []
      }()

   private var name = "Default"

   static let defaultHistory = History()

   private lazy var archiveURL: NSURL = {
      let folderURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
      return folderURL.URLByAppendingPathComponent("\(self.name).archive")
   }()

   private func save() {
      NSKeyedArchiver.archiveRootObject(self.trainings, toFile: self.archiveURL.absoluteString)
   }

   func addData(data: AccelerationData, toTraining training: Training) {
      if self.trainings.first !== training {
         self.trainings.insert(training, atIndex: 0)
      }
      training.addData(data)
      self.save()
   }
}
