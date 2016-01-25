import Foundation
import RealmSwift

public final class Training: Object, Equatable {
   public private(set) dynamic var id = NSUUID().UUIDString
   public private(set) dynamic var best: Double = 0
   public private(set) dynamic var start = NSDate()
   public private(set) dynamic var currentCount = 0
   public private(set) dynamic var tagsVersion = 0

   public let tags = List<Tag>()
   public let data = List<AccelerationData>()

   func deleteTag(tag: Tag) {
      guard let tagIndex = self.tags.indexOf(tag) else {
         return
      }

      tag.deleteTraining(self)
      self.tags.removeAtIndex(tagIndex)

      self.tagsVersion += 1
   }

   func addTag(tag: Tag) {
      if self.tags.contains(tag) {
         return
      }

      self.tags.append(tag)
      tag.addTraining(self)

      self.tagsVersion += 1
   }

   public dynamic var duration: NSTimeInterval {
      return self.data.last?.timestamp ?? 0
   }

   public var activities: [Activity] {
      return self.activitiesData.map { $0.activity! }
   }

   public var activitiesData: Results<AccelerationData> {
      return self.data.filter(NSPredicate(format: "activity != nil"))
   }

   func appendData(data: AccelerationData) {
      if data.total > self.best {
         self.best = data.total
      }

      self.data.append(data)
      self.currentCount = self.data.count
   }

   func appendDataFromArray<T: SequenceType where T.Generator.Element == AccelerationData>(data: T) {

      guard let max = data.maxElement({ $0.total < $1.total }) else {
         return
      }

      if max.total > self.best {
         self.best = max.total
      }

      self.data.appendContentsOf(data)
      self.currentCount = self.data.count
   }

   class func keyPathsForValuesAffectingDuration() -> NSSet {
      return NSSet(object: "currentCount")
   }

   public override static func primaryKey() -> String? {
      return "id"
   }

   public override static func ignoredProperties() -> [String] {
      return ["duration", "activities", "activitiesData"]
   }
}

public func == (lhs: Training, rhs: Training) -> Bool {
   return lhs.id == rhs.id
}

