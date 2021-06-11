import Foundation
import UIKit

class CircularProgressView: UIView {
  private var observation: NSKeyValueObservation?

  private var trackLayer = CAShapeLayer()
  private var progressLayer = CAShapeLayer()

  var onFinished: (() -> Void)? = nil

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    doInit()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    doInit()
  }

  override var intrinsicContentSize: CGSize { .init(width: 20, height: 20) }

  var observedProgress: Progress? {
    didSet {
      guard let observedProgress = observedProgress else {
        observation = nil
        return
      }

      update(animated: false)

      observation = observedProgress.observe(\.fractionCompleted) { [weak self] (_, change) in
        DispatchQueue.main.async {
          self?.update(animated: true)

          if observedProgress.isFinished {
            // Stop observing
            self?.observation = nil
            self?.onFinished?()
          }
        }
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let center = CGPoint(x: bounds.midX, y: bounds.midY)

    trackLayer.path = UIBezierPath(
      arcCenter: center, radius: 10, startAngle: 0, endAngle: 2 * .pi, clockwise: true).cgPath

    progressLayer.path = UIBezierPath(
      arcCenter: center,
      radius: 10,
      startAngle: 0 - .pi / 2.0,
      endAngle: 2 * .pi - .pi / 2.0,
      clockwise: true).cgPath
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      updateColor()
    }
  }

  private func update(animated: Bool) {
    let fractionComplete = CGFloat(observedProgress?.fractionCompleted ?? 0)

    progressLayer.removeAllAnimations()

    let doUpdate = {
      self.progressLayer.strokeEnd = fractionComplete
    }

    if animated {
      UIView.animate(withDuration: 0.2, animations: doUpdate)
    } else {
      doUpdate()
    }
  }

  private func updateColor() {
    trackLayer.strokeColor = UIColor.tertiarySystemFill.cgColor
    progressLayer.strokeColor = UIColor.systemBlue.cgColor
  }

  private func doInit() {
    layer.addSublayer(trackLayer)
    layer.addSublayer(progressLayer)

    trackLayer.lineWidth = 2
    trackLayer.fillColor = UIColor.clear.cgColor

    progressLayer.lineWidth = 2
    progressLayer.fillColor = UIColor.clear.cgColor
    progressLayer.lineCap = .round

    update(animated: false)
    updateColor()
  }
}
