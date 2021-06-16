import Foundation
import UIKit

public extension UIApplication {
  /// Returns the window scene that is running in the foreground and is currently receiving events. If one does not
  /// exist, returns the first connected window scene.
  var currentWindowScene: UIWindowScene? {
    return foregroundActiveWindowScene ?? firstWindowScene
  }

  private var foregroundActiveWindowScene: UIWindowScene? {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
  }

  private var firstWindowScene: UIWindowScene? {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first
  }
}
