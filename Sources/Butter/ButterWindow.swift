import Foundation
import UIKit

class ButterWindow: UIWindow {
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let view = super.hitTest(point, with: event)

    if view is ToastView {
      return view
    }

    return nil
  }
}
