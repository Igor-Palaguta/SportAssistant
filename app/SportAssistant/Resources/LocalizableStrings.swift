// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

import Foundation

enum L10n {
  /// Record
  case AccelerationRecord
  /// Accelerometer
  case AccelerationEvent
  /// No data
  case AccelerationEventEmpty
  /// No peaks
  case NoPeaks
  /// Delete
  case Delete
  /// More
  case More
  /// Cancel
  case Cancel
  /// Ok
  case OK
  /// Share via Email
  case EmailShare
  /// No email accounts. Please add an account Settings->Mail->Add Account
  case CannotSendMail
  /// Add Tag
  case AddTag
  /// Edit Tag
  case EditTag
  /// All Trainings
  case AllTrainings
  /// Edit Tags
  case EditTags
  /// Do you want to delete tag with associated trainings?
  case DeleteTagConfirmation
  /// Yes with trainings
  case DeleteTrainings
  /// Only tag
  case DeleteTag
  /// Are you sure?
  case DeleteTrainingConfirmation
  /// Badminton
  case Badminton
  /// Baseball
  case Baseball
  /// Boxing
  case Boxing
  /// Dance
  case Dance
  /// Golf
  case Golf
  /// Handball
  case Handball
  /// Squash
  case Squash
  /// Table Tennis
  case TableTennis
  /// Tennis
  case Tennis
  /// Volleyball
  case Volleyball
  /// Other
  case Other
}

extension L10n : CustomStringConvertible {
  var description : String { return self.string }

  var string : String {
    switch self {
      case .AccelerationRecord:
        return L10n.tr("AccelerationRecord")
      case .AccelerationEvent:
        return L10n.tr("AccelerationEvent")
      case .AccelerationEventEmpty:
        return L10n.tr("AccelerationEventEmpty")
      case .NoPeaks:
        return L10n.tr("NoPeaks")
      case .Delete:
        return L10n.tr("Delete")
      case .More:
        return L10n.tr("More")
      case .Cancel:
        return L10n.tr("Cancel")
      case .OK:
        return L10n.tr("OK")
      case .EmailShare:
        return L10n.tr("EmailShare")
      case .CannotSendMail:
        return L10n.tr("CannotSendMail")
      case .AddTag:
        return L10n.tr("AddTag")
      case .EditTag:
        return L10n.tr("EditTag")
      case .AllTrainings:
        return L10n.tr("AllTrainings")
      case .EditTags:
        return L10n.tr("EditTags")
      case .DeleteTagConfirmation:
        return L10n.tr("DeleteTagConfirmation")
      case .DeleteTrainings:
        return L10n.tr("DeleteTrainings")
      case .DeleteTag:
        return L10n.tr("DeleteTag")
      case .DeleteTrainingConfirmation:
        return L10n.tr("DeleteTrainingConfirmation")
      case .Badminton:
        return L10n.tr("Badminton")
      case .Baseball:
        return L10n.tr("Baseball")
      case .Boxing:
        return L10n.tr("Boxing")
      case .Dance:
        return L10n.tr("Dance")
      case .Golf:
        return L10n.tr("Golf")
      case .Handball:
        return L10n.tr("Handball")
      case .Squash:
        return L10n.tr("Squash")
      case .TableTennis:
        return L10n.tr("TableTennis")
      case .Tennis:
        return L10n.tr("Tennis")
      case .Volleyball:
        return L10n.tr("Volleyball")
      case .Other:
        return L10n.tr("Other")
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

