import Foundation

enum Sign {
   case Minus
   case Zero
   case Plus
   init(value: Double) {
      if value > 0 {
         self = Plus
      } else if value < 0 {
         self = Minus
      } else {
         self = Zero
      }
   }
}

private extension Double {
   var isSignificant: Bool {
      return self > 4
   }
}

struct PointValue {
   let value: Double
   let data: AccelerationEvent
}

func < (point: PointValue, value: Double) -> Bool { return point.value < value }
func > (point: PointValue, value: Double) -> Bool { return point.value > value }
func == (point: PointValue, value: Double) -> Bool { return point.value == value }

final class Range {

   let initial: PointValue
   private(set) var final: PointValue

   private(set) var globalMin: PointValue
   private(set) var globalMax: PointValue

   private(set) var localMinMax: [PointValue]
   private(set) var growSign = Sign.Zero

   init(initial: PointValue) {
      self.initial = initial
      self.final = initial

      self.globalMin = initial
      self.globalMax = initial
      self.localMinMax = []
   }

   func addValue(value: PointValue) {
      let newSign = Sign(value: value.value - self.final.value)
      if newSign == .Zero {
         return
      }

      if self.growSign == .Zero {
         self.growSign = newSign
      } else if self.growSign != newSign {
         self.localMinMax.append(self.final)
         self.growSign = newSign
      }

      if value.value > self.globalMax.value {
         self.globalMax = value
      }
      if value.value < self.globalMin.value {
         self.globalMin = value
      }
      self.final = value
   }
}

typealias RangePredicate = (Range) -> Bool
typealias AccelerationEventRangePredicate = (AccelerationEventRange) -> Bool

extension AccelerationEvent {
   func point(field: AccelerationEventField) -> PointValue {
      return PointValue(value: self[field], data: self)
   }
}

public final class AccelerationEventRange: CustomStringConvertible {

   var x: Range
   var y: Range
   var z: Range
   var total: Range
   var all: [AccelerationEvent]

   init(initial: AccelerationEvent) {
      self.x = Range(initial: initial.point(.x))
      self.y = Range(initial: initial.point(.y))
      self.z = Range(initial: initial.point(.z))
      self.total = Range(initial: initial.point(.total))
      self.all = [initial]
   }

   func addData(data: AccelerationEvent, final: Bool = false) {
      self.x.addValue(data.point(.x))
      self.y.addValue(data.point(.y))
      self.z.addValue(data.point(.z))
      self.total.addValue(data.point(.total))
      if !final {
         self.all.append(data)
      }
   }

   subscript(id: AccelerationEventField) -> Range {
      get {
         switch id {
         case .x:
            return self.x
         case .y:
            return self.y
         case .z:
            return self.z
         case .total:
            return self.total
         }
      }
   }

   public var description: String {
      return self.all.description
   }
}

struct Template<AttributesType> {
   let predicates: [AccelerationEventRangePredicate]
   let attributes: AttributesType

   init(attributes: AttributesType, predicates: [AccelerationEventRangePredicate]) {
      self.attributes = attributes
      self.predicates = predicates
   }

   func isMatchedRange(range: AccelerationEventRange) -> Bool {
      let failed = self.predicates.contains { !$0(range) }
      return !failed
   }
}

public enum AnalyzerResult<AttributesType> {
   case Analyzing
   case FoundRange(AttributesType?, AccelerationEventRange)
   case NotFromRange([AccelerationEvent])

   public var data: [AccelerationEvent] {
      switch self {
      case Analyzing:
         return []
      case FoundRange(_, let range):
         return range.all
      case NotFromRange(let data):
         return data
      }
   }

   public var peak: (attributes: AttributesType, data: AccelerationEvent)? {
      if case .FoundRange(.Some(let attributes), let range) = self {
         return (attributes, range.total.globalMax.data)
      }
      return nil
   }
}

public class Analyzer<AttributesType> {

   private var currentRange: AccelerationEventRange?
   private let templates: [Template<AttributesType>]
   private let defaultValue: AttributesType?

   public var outstandingData: [AccelerationEvent] {
      return self.currentRange.map { $0.all } ?? []
   }

   init(templates: [Template<AttributesType>], defaultValue: AttributesType) {
      self.templates = templates
      self.defaultValue = defaultValue
   }

   private func attributesForRange(range: AccelerationEventRange) -> AttributesType? {
      if let index = self.templates.indexOf({$0.isMatchedRange(range)}) {
         return self.templates[index].attributes
      }
      return nil
   }

   public func analyzeData(data: AccelerationEvent) -> AnalyzerResult<AttributesType> {
      guard let currentRange = self.currentRange else {
         self.currentRange = AccelerationEventRange(initial: data)
         return .Analyzing
      }

      if data.total.isSignificant {
         currentRange.addData(data)
         return .Analyzing
      }

      self.currentRange = AccelerationEventRange(initial: data)

      if currentRange.total.globalMax.value.isSignificant {
         currentRange.addData(data, final: true)
         return .FoundRange(self.attributesForRange(currentRange) ?? self.defaultValue,
            currentRange)
      }

      return .NotFromRange(currentRange.all)
   }
}

public enum Hand: String {
   case Left
   case Right
}

public enum TableTennisMotion: CustomStringConvertible {
   case RightTopSpin(Hand)
   case LeftTopSpin(Hand)
   case Unknown

   public var description: String {
      switch self {
      case RightTopSpin(let hand):
         return "\(hand) Hand Right Top Spin"
      case LeftTopSpin(let hand):
         return "\(hand) Hand Left Top Spin"
      case Unknown:
         return "Unknown motion"
      }
   }
}

private func predicateForField(field: AccelerationEventField,
   predicate: RangePredicate) -> AccelerationEventRangePredicate {
      return {
         AccelerationEventRange in
         return predicate(AccelerationEventRange[field])
      }
}

public final class TableTennisAnalyzer: Analyzer<TableTennisMotion> {

   public init() {
      let rightHandRightTopSpin = Template(attributes: TableTennisMotion.RightTopSpin(.Right),
         predicates: [
            predicateForField(.x) { $0.globalMin < 0 && abs($0.globalMin.value) > abs($0.globalMax.value) },
            predicateForField(.z) {
               range in
               if range.initial < 0,
                  let firstExtremum = range.localMinMax.first
                  where firstExtremum > range.initial.value {
                     return true
               }
               return false
            }
         ])

      let rightHandLeftTopSpin = Template(attributes: TableTennisMotion.LeftTopSpin(.Right),
         predicates: [
            predicateForField(.x) { $0.globalMin < 0 && abs($0.globalMin.value) > abs($0.globalMax.value) },
            predicateForField(.z) { $0.initial > 0 }
         ])

      let leftHandRightTopSpin = Template(attributes: TableTennisMotion.RightTopSpin(.Left),
         predicates: [
            predicateForField(.x) { $0.globalMax > 0 && abs($0.globalMax.value) > abs($0.globalMin.value) },
            predicateForField(.z) { $0.initial < 0 }
         ])

      let leftHandLeftTopSpin = Template(attributes: TableTennisMotion.LeftTopSpin(.Left),
         predicates: [
            predicateForField(.x) { $0.globalMax > 0 && abs($0.globalMax.value) > abs($0.globalMin.value) },
            predicateForField(.z) { $0.initial > 0 }
         ])

      super.init(templates: [rightHandRightTopSpin,
         rightHandLeftTopSpin,
         leftHandRightTopSpin,
         leftHandLeftTopSpin], defaultValue: .Unknown)
   }
}
