// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

import UIKit

extension UIColor {
  convenience init(rgbaValue: UInt32) {
    let red   = CGFloat((rgbaValue >> 24) & 0xff) / 255.0
    let green = CGFloat((rgbaValue >> 16) & 0xff) / 255.0
    let blue  = CGFloat((rgbaValue >>  8) & 0xff) / 255.0
    let alpha = CGFloat((rgbaValue      ) & 0xff) / 255.0

    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}

extension UIColor {
  enum Name {
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#000000"></span>
    /// Alpha: 0% <br/> (0x00000000)
    case __Http
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#3aa6d0"></span>
    /// Alpha: 100% <br/> (0x3aa6d0ff)
    case Base
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff2c00"></span>
    /// Alpha: 100% <br/> (0xff2c00ff)
    case Destructive
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#63cd90"></span>
    /// Alpha: 100% <br/> (0x63cd90ff)
    case Record

    var rgbaValue: UInt32! {
      switch self {
      case .__Http: return 0x00000000
      case .Base: return 0x3aa6d0ff
      case .Destructive: return 0xff2c00ff
      case .Record: return 0x63cd90ff
      }
    }
  }

  convenience init(named name: Name) {
    self.init(rgbaValue: name.rgbaValue)
  }
}

