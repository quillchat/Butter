import Foundation
import UIKit

extension NSLayoutConstraint {
  func priority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
    self.priority = priority
    return self
  }
}
