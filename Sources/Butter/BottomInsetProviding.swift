import Foundation
import UIKit

/// A view controller that specifies the bottom inset for toasts.
/// - Tag: BottomInsetProviding
public protocol BottomInsetProviding: UIViewController {
  var bottomInset: CGFloat { get }
}
