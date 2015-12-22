import Foundation

protocol BaseAccelerationData {
   var date: NSDate! { get }
   var x: Double { get }
   var y: Double { get }
   var z: Double { get }
   var total: Double { get }
}
