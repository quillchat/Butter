import Foundation
import UIKit

extension ButterViewController {
  private struct Item {
    let toastView: ToastView
    var edge: Edge
    var config: ItemConfig
    var dismissDispatchWorkItem: DispatchWorkItem?
    var fadeOutAnimator: UIViewPropertyAnimator?
    var topConstraint: NSLayoutConstraint
    var bottomConstraint: NSLayoutConstraint
    var onTap: (() -> Void)?
  }

  private struct ItemConfig: Equatable {
    var inset: Inset
    var userInterfaceStyle: UIUserInterfaceStyle
    var interfaceOrientation: UIInterfaceOrientation
  }

  fileprivate enum Inset: Equatable {
    case top(CGFloat)
    case bottom(CGFloat)
  }
}

extension ButterViewController.Inset {
  init(_ constant: CGFloat, edge: Edge) {
    switch edge {
    case .top:
      self = .top(constant)
    case .bottom:
      self = .bottom(constant)
    }
  }
}

class ButterViewController: UIViewController {
  private static let fadeDuration: TimeInterval = 0.3
  private static let additionalInset: CGFloat = 16

  private var currentItem: Item?

  private var queue = [Toast]()

  private var timer: Timer!

  /// The rootViewController of the main window.
  weak var mainRootViewController: UIViewController?

  weak var windowScene: UIWindowScene?

  override func viewDidLoad() {
    timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { [weak self] _ in
      guard let self = self else { return }
      guard var currentItem = self.currentItem else { return }

      let newItemConfig = self.itemConfig(edge: currentItem.edge)

      guard newItemConfig != currentItem.config else { return }

      let needsLayout = currentItem.config.inset != newItemConfig.inset

      if needsLayout {
        switch newItemConfig.inset {
        case let .top(inset):
          currentItem.topConstraint.constant = inset
          currentItem.topConstraint.priority = .defaultHigh
          currentItem.bottomConstraint.priority = .defaultLow
        case let .bottom(inset):
          currentItem.bottomConstraint.constant = -inset
          currentItem.bottomConstraint.priority = .defaultHigh
          currentItem.topConstraint.priority = .defaultLow
        }
      }

      currentItem.toastView.overrideUserInterfaceStyle = newItemConfig.userInterfaceStyle

      if currentItem.config.interfaceOrientation != newItemConfig.interfaceOrientation {
        // The interfaceOrientation has changed so reset the rootViewController. This will force the view controller to
        // reorient itself.
        let window = self.view.window

        window?.rootViewController = nil
        window?.rootViewController = self
      } else if needsLayout {
        UIView.animate(withDuration: 0.3) {
          currentItem.toastView.superview?.layoutIfNeeded()
        }
      }

      currentItem.config = newItemConfig

      self.currentItem = currentItem
    })
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    UIInterfaceOrientationMask(interfaceOrientation: windowSceneInterfaceOrientation) ??
      super.supportedInterfaceOrientations
  }

  override var shouldAutorotate: Bool { true }

  /// Enqueues the given toast. If a toast with the same ID is already visible or enqueued, it is replaced.
  func enqueue(_ toast: Toast) {
    // Replace the current toast if necessary.
    if var currentItem = currentItem, currentItem.toastView.toast?.id == toast.id {
      currentItem.toastView.layer.removeAllAnimations()
      currentItem.fadeOutAnimator?.stopAnimation(true)
      currentItem.fadeOutAnimator = nil
      currentItem.toastView.alpha = 1

      currentItem.toastView.toast = toast
      currentItem.edge = toast.edge
      currentItem.dismissDispatchWorkItem?.cancel()
      currentItem.dismissDispatchWorkItem = makeDismissDispatchWorkItem(for: toast)

      self.currentItem = currentItem
      return
    }

    // Replace an existing toast if one already exists with the same ID as the one being enqueued.
    if let existingIndex = queue.firstIndex(withID: toast.id) {
      queue[existingIndex] = toast
    } else {
      queue.append(toast)
    }

    if currentItem == nil {
      dequeue()
    }
  }

  func dequeue() {
    guard !queue.isEmpty else { fatalError() }

    let toast = queue.removeFirst()
    let toastView = ToastView()

    toastView.onProgressFinished = { [weak self] in
      guard let self = self else { return }
      guard let currentItem = self.currentItem else { return }

      if currentItem.toastView === toastView {
        toastView.isUserInteractionEnabled = false
        self.dismissCurrentToastViewIfNeeded()
      }
    }

    toastView.onTap = { [weak self] in
      guard let self = self else { return }
      guard let currentItem = self.currentItem else { return }
      guard let toast = currentItem.toastView.toast else { return }

      // This ensures that if the action presents a view with an input accessory view, that input accessory view
      // appears.
      self.mainRootViewController?.view.window?.makeKey()

      toast.onTap?()

      if currentItem.toastView === toastView && toast.shouldDismissWhenTapped {
        toastView.isUserInteractionEnabled = false
        self.dismissCurrentToastViewIfNeeded()
      }
    }

    view.addSubview(toastView)

    toastView.toast = toast

    let itemConfig = self.itemConfig(edge: toast.edge)

    toastView.overrideUserInterfaceStyle = itemConfig.userInterfaceStyle

    NSLayoutConstraint.activate([
      toastView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      toastView.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor, constant: 16),
    ])

    let topConstraint = toastView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
    let bottomConstraint = toastView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)

    switch itemConfig.inset {
    case let .top(inset):
      topConstraint.constant = inset
      topConstraint.priority = .defaultHigh
      bottomConstraint.priority = .defaultLow
    case let .bottom(inset):
      bottomConstraint.constant = -inset
      topConstraint.priority = .defaultLow
      bottomConstraint.priority = .defaultHigh
    }

    topConstraint.isActive = true
    bottomConstraint.isActive = true

    toastView.alpha = 0
    toastView.transform = CGAffineTransform.init(scaleX: 0.3, y: 0.3)

    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: []) {
      toastView.transform = CGAffineTransform.identity
    }

    UIView.animate(withDuration: 0.3) {
      toastView.alpha = 1
    }

    currentItem = Item(
      toastView: toastView,
      edge: toast.edge,
      config: itemConfig,
      dismissDispatchWorkItem: makeDismissDispatchWorkItem(for: toast),
      topConstraint: topConstraint,
      bottomConstraint: bottomConstraint)
  }

  func dismiss(id: UUID) {
    if currentItem?.toastView.toast?.id == id {
      dismissCurrentToastViewIfNeeded()
    } else {
      let index = queue.firstIndex { $0.id == id }

      if let index = index {
        queue.remove(at: index)
      }
    }
  }

  func dismissCurrentToastViewIfNeeded() {
    guard currentItem != nil else { return }

    // Remove animations in case it was still appearing or disappearing.
    currentItem?.toastView.layer.removeAllAnimations()
    currentItem?.fadeOutAnimator?.stopAnimation(true)
    currentItem?.fadeOutAnimator = nil
    currentItem?.dismissDispatchWorkItem?.cancel()

    doDismissCurrentToastView()
  }

  private func doDismissCurrentToastView() {
    guard let currentItem = self.currentItem else {
      print("Butter attempted to dismiss a toast when one wasn't current!")
      return
    }

    currentItem.toastView.isUserInteractionEnabled = false

    let fadeOutAnimator =
      UIViewPropertyAnimator.runningPropertyAnimator(withDuration: Self.fadeDuration, delay: 0, options: []) {

      currentItem.toastView.alpha = 0
    } completion: { finalPosition in
      guard finalPosition == .end else { return }

      self.currentItem = nil

      currentItem.toastView.removeFromSuperview()

      if !self.queue.isEmpty {
        self.dequeue()
      }
    }

    self.currentItem?.fadeOutAnimator = fadeOutAnimator
  }

  private func itemConfig(edge: Edge) -> ItemConfig {
    let interfaceOrientation = self.windowSceneInterfaceOrientation

    guard let mainRootViewController = self.mainRootViewController else {
      return .init(
        inset: .init(Self.additionalInset, edge: edge),
        userInterfaceStyle: .unspecified,
        interfaceOrientation: interfaceOrientation)
    }

    let topViewController = mainRootViewController.topViewController { viewController in
      if viewController.isModalInPresentation {
        let modalPresentationStyle = viewController.modalPresentationStyle

        if modalPresentationStyle == .popover { return false }

        if modalPresentationStyle == .pageSheet || modalPresentationStyle == .formSheet {
          let traitCollection = viewController.traitCollection

          if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            return false
          }
        }
      }

      if viewController is UIAlertController { return false }

      return true
    }

    let inset = topViewController.inset(edge: edge)

    return .init(
      inset: .init(inset + Self.additionalInset, edge: edge),
      userInterfaceStyle: topViewController.overrideUserInterfaceStyle,
      interfaceOrientation: interfaceOrientation)
  }

  private var windowSceneInterfaceOrientation: UIInterfaceOrientation {
    windowScene?.interfaceOrientation ?? .unknown
  }

  private func makeDismissDispatchWorkItem(for toast: Toast) -> DispatchWorkItem? {
    guard let duration = toast.duration else { return nil }

    let dispatchWorkItem = DispatchWorkItem { [weak self] in
      guard let self = self else { return }
      self.doDismissCurrentToastView()
    }

    let deadline: DispatchTime = .now() + .milliseconds(Int(duration) * 1000)

    DispatchQueue.main.asyncAfter(deadline: deadline, execute: dispatchWorkItem)

    return dispatchWorkItem
  }
}
