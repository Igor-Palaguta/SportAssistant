// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

import Foundation

enum L10n {
  /// Record
  case AccelerationRecord
  /// Accelerometer
  case AccelerationData
  /// No data
  case AccelerationDataEmpty
  /// No peaks
  case NoPeaks
  /// Delete
  case Delete
  /// Cancel
  case Cancel
  /// Ok
  case OK
  /// Share via Email
  case EmailShare
  /// No email accounts. Please add an account Settings->Mail->Add Account
  case CannotSendMail
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
      case .NoPeaks:
        return L10n.tr("NoPeaks")
      case .Delete:
        return L10n.tr("Delete")
      case .Cancel:
        return L10n.tr("Cancel")
      case .OK:
        return L10n.tr("OK")
      case .EmailShare:
        return L10n.tr("EmailShare")
      case .CannotSendMail:
        return L10n.tr("CannotSendMail")
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

