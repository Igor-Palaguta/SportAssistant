// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

import Foundation

enum L10n {
  /// Are you sure?
  case DeleteTrainingTitle
  /// Delete
  case Delete
  /// Cancel
  case Cancel
  /// Start
  case Start
  /// Stop
  case Stop
  /// Trainings (%d)
  case TrainingsCountFormat(Int)
  /// ↑
  case Ascending
  /// ↓
  case Descending
  /// Other
  case Other
  /// Best: %@
  case BestFormat(String)
  /// Last: %@
  case LastFormat(String)
}

extension L10n : CustomStringConvertible {
  var description : String { return self.string }

  var string : String {
    switch self {
      case .DeleteTrainingTitle:
        return L10n.tr("DeleteTrainingTitle")
      case .Delete:
        return L10n.tr("Delete")
      case .Cancel:
        return L10n.tr("Cancel")
      case .Start:
        return L10n.tr("Start")
      case .Stop:
        return L10n.tr("Stop")
      case .TrainingsCountFormat(let p0):
        return L10n.tr("TrainingsCountFormat", p0)
      case .Ascending:
        return L10n.tr("Ascending")
      case .Descending:
        return L10n.tr("Descending")
      case .Other:
        return L10n.tr("Other")
      case .BestFormat(let p0):
        return L10n.tr("BestFormat", p0)
      case .LastFormat(let p0):
        return L10n.tr("LastFormat", p0)
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

