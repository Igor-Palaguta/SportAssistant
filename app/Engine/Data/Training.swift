import Foundation
import RealmSwift

public final class Training: Object, Equatable {
   public private(set) dynamic var id = NSUUID().UUIDString
   public private(set) dynamic var best: Double = 0
   public private(set) dynamic var start = NSDate()
   public private(set) dynamic var currentCount = 0
   public private(set) dynamic var tagsVersion = 0

   public let tags = List<Tag>()
   public let events = List<AccelerationEvent>()

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
      return self.events.last?.timestamp ?? 0
   }

   public var activities: [Activity] {
      return self.activityEvents.map { $0.activity! }
   }

   public var activityEvents: Results<AccelerationEvent> {
      return self.events.filter(NSPredicate(format: "activity != nil"))
   }

   func appendEvent(event: AccelerationEvent) {
      if event.total > self.best {
         self.best = event.total
      }

      self.events.append(event)
      self.currentCount = self.events.count
   }

   func appendEvents<T: SequenceType where T.Generator.Element == AccelerationEvent>(events: T) {

      guard let max = events.maxElement({ $0.total < $1.total }) else {
         return
      }

      if max.total > self.best {
         self.best = max.total
      }

      self.events.appendContentsOf(events)
      self.currentCount = self.events.count
   }

   class func keyPathsForValuesAffectingDuration() -> NSSet {
      return NSSet(object: "currentCount")
   }

   public override static func primaryKey() -> String? {
      return "id"
   }

   public override static func ignoredProperties() -> [String] {
      return ["duration", "activities", "activitityEvents"]
   }
}

public func == (lhs: Training, rhs: Training) -> Bool {
   return lhs.id == rhs.id
}

