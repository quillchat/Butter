import Foundation
import UIKit

extension UIViewController {
  /// Finds the top-most presented `UIViewController` by walking the `presentedViewController` hierarchy. Also steps
  /// into the `topViewController` of a `UINavigationController` and the `selectedViewController` of a
  /// `UITabBarController`.
  /// - Parameter canBeTopViewController: Indicate whether the given view controller can become the top view controller.
  func topViewController(canBeTopViewController: (UIViewController) -> Bool) -> UIViewController {
    var topViewController = self

    while let nextViewController = nextViewController(of: topViewController),
      canBeTopViewController(nextViewController) {

      topViewController = nextViewController
    }

    return topViewController
  }

  func bottomInset() -> CGFloat {
    if let bottomInsetProviding = self as? BottomInsetProviding {
      return bottomInsetProviding.bottomInset
    } else {
      return view.safeAreaInsets.bottom
    }
  }

  private func nextViewController(of viewController: UIViewController) -> UIViewController? {
    if let presentedViewController = viewController.presentedViewController {
      return presentedViewController
    }

    if let navigationController = viewController as? UINavigationController,
      let topViewController = navigationController.topViewController {

      return topViewController
    }

    if let tabBarController = viewController as? UITabBarController,
      let selectedViewController = tabBarController.selectedViewController {

      return selectedViewController
    }

    return nil
  }
}
