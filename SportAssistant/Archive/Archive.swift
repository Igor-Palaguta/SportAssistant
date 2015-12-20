import Foundation

protocol ArchiveDelegate {
   
}

final class Archive {

   static let sharedArchive = Archive()

   var count: Int {
      return self.trainings.count
   }

   func addTraining(training: Training) {
      self.trainings.append(training)
      self.save()
   }

   func removeTraining(training: Training) {

      //self.trainings.in
   }

   subscript(index: Int) -> Training {
      get {
         return self.trainings[index]
      }
   }

   private(set) lazy var trainings: [Training] = {
      [unowned self] in
      if let archive = NSKeyedUnarchiver.unarchiveObjectWithFile(self.archiveURL.absoluteString) as? [Training] {
         return archive
      }
      return []
      }()

   private lazy var archiveURL: NSURL = {
      let folderURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
      return folderURL.URLByAppendingPathComponent("Trainings.archive")
   }()

   private func save() {
      NSKeyedArchiver.archiveRootObject(self.trainings, toFile: self.archiveURL.absoluteString)
   }
}
