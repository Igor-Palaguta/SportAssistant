import UIKit

protocol ReusableView: class {
   static var viewIdentifier: String { get }
}

extension ReusableView {
   static var viewIdentifier: String {
      return String(Self)
   }
}

protocol ReusableClassView: ReusableView {
}

protocol ReusableNibView: ReusableView {
   static var nibName: String { get }
}

extension ReusableNibView {
   static var nibName: String {
      return self.viewIdentifier
   }

   static var nib: UINib {
      return UINib(nibName: self.nibName, bundle: nil)
   }
}

func create<View: ReusableNibView>() -> View {
   return View.nib.instantiateWithOwner(nil, options: nil).first as! View
}

extension UITableView {
   func registerCell<Cell: ReusableNibView>(type: Cell.Type) {
      self.registerNib(Cell.nib, forCellReuseIdentifier: Cell.viewIdentifier)
   }

   func registerCell<Cell: ReusableClassView>(type: Cell.Type) {
      self.registerClass(type, forCellReuseIdentifier: Cell.viewIdentifier)
   }

   func dequeueCell<Cell: ReusableView>() -> Cell {
      return self.dequeueReusableCellWithIdentifier(Cell.viewIdentifier) as! Cell
   }

   func dequeueCellForIndexPath<Cell: ReusableView>(indexPath: NSIndexPath) -> Cell {
      return self.dequeueReusableCellWithIdentifier(Cell.viewIdentifier, forIndexPath: indexPath) as! Cell
   }
}

extension UICollectionView {
   func registerCell<Cell: ReusableNibView>(type: Cell.Type) {
      self.registerNib(Cell.nib, forCellWithReuseIdentifier: Cell.viewIdentifier)
   }

   func registerCell<Cell: ReusableClassView>(type: Cell.Type) {
      self.registerClass(type, forCellWithReuseIdentifier: Cell.viewIdentifier)
   }

   func dequeueCellForIndexPath<Cell: ReusableView>(indexPath: NSIndexPath) -> Cell {
      return self.dequeueReusableCellWithReuseIdentifier(Cell.viewIdentifier, forIndexPath: indexPath) as! Cell
   }

   func registerSupplementaryView<View: ReusableClassView>(type: View.Type, forSupplementaryViewOfKind elementKind: String) {
      self.registerClass(type, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: View.viewIdentifier)
   }

   func registerSupplementaryView<View: ReusableNibView>(type: View.Type, forSupplementaryViewOfKind elementKind: String) {
      self.registerNib(View.nib, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: View.viewIdentifier)
   }

   func dequeueReusableSupplementaryViewOfKind<View: ReusableView>(elementKind: String, forIndexPath indexPath: NSIndexPath) -> View {
      return self.dequeueReusableSupplementaryViewOfKind(elementKind, withReuseIdentifier: View.viewIdentifier, forIndexPath: indexPath) as! View
   }
}
