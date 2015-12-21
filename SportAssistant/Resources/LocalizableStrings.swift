// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

import Foundation

enum L10n {
  /// Record
  case AccelerationRecord
  /// Accelerometer
  case AccelerationData
  /// No data
  case AccelerationDataEmpty
}

extension L10n : CustomStringConvertible {
  var description : String { return self.string }

  var string : String {
    switch self {
      case .AccelerationRecord:
        return L10n.tr("AccelerationRecord")
      case .AccelerationData:
        return L10n.tr("AccelerationData")
      case .AccelerationDataEmpty:
        return L10n.tr("AccelerationDataEmpty")
    }
  }

  private static func tr(key: String, _ args: CVarArgType...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return String(format: format, arguments: args)
  }
}

func tr(key: L10n) -> String {
  return key.string
}

