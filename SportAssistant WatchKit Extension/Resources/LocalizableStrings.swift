// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

import Foundation

enum L10n {
  /// Are you sure?
  case DeleteIntervalTitle
  /// Delete
  case Delete
  /// Cancel
  case Cancel
}

extension L10n : CustomStringConvertible {
  var description : String { return self.string }

  var string : String {
    switch self {
      case .DeleteIntervalTitle:
        return L10n.tr("DeleteIntervalTitle")
      case .Delete:
        return L10n.tr("Delete")
      case .Cancel:
        return L10n.tr("Cancel")
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
