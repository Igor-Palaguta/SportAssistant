import Foundation

protocol JSONAble {}

extension JSONAble {
   func toDictionary() -> [String: Any] {
      var result = [String: Any]()
      let mirror = Mirror(reflecting: self)
      for child in mirror.children {
         if let key = child.label {
            result[key] = child.value
         }
      }
      return result
   }
}