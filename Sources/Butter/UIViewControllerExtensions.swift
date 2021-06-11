import Foundation
import UIKit

extension UIViewController {
  /// Finds the top-most presented UIViewController by walking the `presentedViewController` hierarchy.
  func topViewController(canBeTopViewController: (UIViewController) -> Bool) -> UIViewController {
    var topViewController = self

    while let presentedViewController = topViewController.presentedViewController,
      canBeTopViewController(presentedViewController) {

      topViewController = presentedViewController
    }

    return topViewController
  }
}
