import Foundation
import UIKit

extension UIInterfaceOrientationMask {
  init?(interfaceOrientation: UIInterfaceOrientation) {
    switch interfaceOrientation {
    case .landscapeLeft:
      self = .landscapeLeft
    case .landscapeRight:
      self = .landscapeRight
    case .portrait:
      self = .portrait
    case .portraitUpsideDown:
      self = .portraitUpsideDown
    case .unknown:
      return nil
    @unknown default:
      return nil
    }
  }
}
