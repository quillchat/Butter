import Foundation
import UIKit

extension UIView {
  func constrainEdgesEqualToSuperview() {
    guard let superview = superview else { return }

    NSLayoutConstraint.activate([
      leadingAnchor.constraint(equalTo: superview.leadingAnchor),
      trailingAnchor.constraint(equalTo: superview.trailingAnchor),
      topAnchor.constraint(equalTo: superview.topAnchor),
      bottomAnchor.constraint(equalTo: superview.bottomAnchor)
    ])
  }
}
