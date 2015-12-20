import Foundation


enum Hand: String {
   case Left
   case Right
}

enum Side: String {
   case Backhand
   case Forehand
}

class Momement: NSObject, NSCoding {
   let time: NSDate
   let hand: Hand
   let side: Side
   let acceleration: Double

   init(time: NSDate, hand: Hand, side: Side, acceleration: Double) {
      self.time = time
      self.hand = hand
      self.side = side
      self.acceleration = acceleration
      super.init()
   }

   func encodeWithCoder(aCoder: NSCoder) {
      aCoder.encodeObject(self.time, forKey: "time")
      aCoder.encodeObject(self.hand.rawValue, forKey: "hand")
      aCoder.encodeObject(self.side.rawValue, forKey: "side")
      aCoder.encodeDouble(self.acceleration, forKey: "acceleration")
   }

   required init?(coder aDecoder: NSCoder) {
      self.time = aDecoder.decodeObjectForKey("time") as! NSDate
      self.hand = Hand(rawValue: aDecoder.decodeObjectForKey("hand") as! String)!
      self.side = Side(rawValue: aDecoder.decodeObjectForKey("side") as! String)!
      self.acceleration = aDecoder.decodeDoubleForKey("acceleration")
      super.init()
   }
}

class Training: NSObject, NSCoding {
   let movements: [Momement]

   init(movements: [Momement]) {
      self.movements = movements
   }

   func encodeWithCoder(aCoder: NSCoder) {
      aCoder.encodeObject(self.movements, forKey: "movements")
   }

   required init?(coder aDecoder: NSCoder) {
      self.movements = aDecoder.decodeObjectForKey("movements") as! [Momement]
      super.init()
   }
}

extension Training {
   func toDictionary() -> [String: AnyObject] {
      return ["movement": 1]
   }
}


