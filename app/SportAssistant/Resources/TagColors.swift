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
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#7f8c8d"></span>
    /// Alpha: 100% <br/> (0x7f8c8dff)
    case Asbestos
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#2980b9"></span>
    /// Alpha: 100% <br/> (0x2980b9ff)
    case BelizeHole
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#16a085"></span>
    /// Alpha: 100% <br/> (0x16a085ff)
    case GreenSea
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#2c3e50"></span>
    /// Alpha: 100% <br/> (0x2c3e50ff)
    case MidnightBlue
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#27ae60"></span>
    /// Alpha: 100% <br/> (0x27ae60ff)
    case Nephritis
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#f39c12"></span>
    /// Alpha: 100% <br/> (0xf39c12ff)
    case Orange
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#c0392b"></span>
    /// Alpha: 100% <br/> (0xc0392bff)
    case Pomegranate
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#d35400"></span>
    /// Alpha: 100% <br/> (0xd35400ff)
    case Pumpkin
    /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#8e44ad"></span>
    /// Alpha: 100% <br/> (0x8e44adff)
    case Wisteria

    var rgbaValue: UInt32! {
      switch self {
      case .Asbestos: return 0x7f8c8dff
      case .BelizeHole: return 0x2980b9ff
      case .GreenSea: return 0x16a085ff
      case .MidnightBlue: return 0x2c3e50ff
      case .Nephritis: return 0x27ae60ff
      case .Orange: return 0xf39c12ff
      case .Pomegranate: return 0xc0392bff
      case .Pumpkin: return 0xd35400ff
      case .Wisteria: return 0x8e44adff
      }
    }
  }

  convenience init(named name: Name) {
    self.init(rgbaValue: name.rgbaValue)
  }
}

