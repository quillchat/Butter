import Foundation
import UIKit

extension ButterViewController {
  private struct Item {
    let toastView: ToastView
    var config: ItemConfig
    var dismissDispatchWorkItem: DispatchWorkItem?
    var bottomConstraint: NSLayoutConstraint
    var onTap: (() -> Void)?
  }

  private struct ItemConfig: Equatable {
    var bottomInset: CGFloat
    var userInterfaceStyle: UIUserInterfaceStyle
    var interfaceOrientation: UIInterfaceOrientation
  }
}

class ButterViewController: UIViewController {
  private static let fadeDuration: TimeInterval = 0.3
  private static let bottomInset: CGFloat = 16

  private var currentItem: Item?

  private var queue = [Toast]()

  private var timer: Timer!

  /// The rootViewController of the main window.
  weak var rootViewController: UIViewController?

  override func viewDidLoad() {
    timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { [weak self] _ in
      guard let self = self else { return }
      guard var currentItem = self.currentItem else { return }

      let itemConfig = self.itemConfig()

      guard itemConfig != currentItem.config else { return }

      let needsLayout = currentItem.config.bottomInset != itemConfig.bottomInset

      if needsLayout {
        currentItem.bottomConstraint.constant = -itemConfig.bottomInset
      }

      currentItem.toastView.overrideUserInterfaceStyle = itemConfig.userInterfaceStyle

      if currentItem.config.interfaceOrientation != itemConfig.interfaceOrientation {
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

      currentItem.config = itemConfig

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
      currentItem.toastView.toast = toast
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
      self.rootViewController?.view.window?.makeKey()

      toast.onTap?()

      if currentItem.toastView === toastView && toast.shouldDismissWhenTapped {
        toastView.isUserInteractionEnabled = false
        self.dismissCurrentToastViewIfNeeded()
      }
    }

    view.addSubview(toastView)

    toastView.toast = toast

    let itemConfig = self.itemConfig()

    toastView.overrideUserInterfaceStyle = itemConfig.userInterfaceStyle

    NSLayoutConstraint.activate([
      toastView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      toastView.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor, constant: 16),
    ])

    let bottomConstraint = toastView.bottomAnchor.constraint(
      equalTo: view.bottomAnchor, constant: -itemConfig.bottomInset)

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
      config: itemConfig,
      dismissDispatchWorkItem: makeDismissDispatchWorkItem(for: toast),
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
    guard let currentItem = self.currentItem else { return }

    // Remove animations in case it was still appearing.
    currentItem.toastView.layer.removeAllAnimations()
    currentItem.dismissDispatchWorkItem?.cancel()

    doDismissCurrentToastView()
  }

  private func doDismissCurrentToastView() {
    guard let currentItem = self.currentItem else { fatalError() }

    currentItem.toastView.isUserInteractionEnabled = false

    self.currentItem = nil

    UIView.animate(withDuration: Self.fadeDuration, animations: {
      currentItem.toastView.alpha = 0
    }, completion: { [weak self] _ in
      guard let weakSelf = self else { return }

      currentItem.toastView.removeFromSuperview()

      if !weakSelf.queue.isEmpty {
        weakSelf.dequeue()
      }
    })
  }

  private func itemConfig() -> ItemConfig {
    let interfaceOrientation = self.windowSceneInterfaceOrientation

    guard let rootViewController = self.rootViewController else {
      return .init(
        bottomInset: Self.bottomInset, userInterfaceStyle: .unspecified, interfaceOrientation: interfaceOrientation)
    }

    let topViewController = rootViewController.topViewController { viewController in
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

    return .init(
      bottomInset: topViewController.bottomInset() + Self.bottomInset,
      userInterfaceStyle: topViewController.overrideUserInterfaceStyle,
      interfaceOrientation: interfaceOrientation)
  }

  private var windowSceneInterfaceOrientation: UIInterfaceOrientation {
    view.window?.windowScene?.interfaceOrientation ?? .portrait
  }

  private func makeDismissDispatchWorkItem(for toast: Toast) -> DispatchWorkItem? {
    guard let duration = toast.duration else { return nil }

    let dispatchWorkItem = DispatchWorkItem { [weak self] in
      guard let weakSelf = self else { return }

      weakSelf.doDismissCurrentToastView()
    }

    let deadline: DispatchTime = .now() + .milliseconds(Int(duration) * 1000)

    DispatchQueue.main.asyncAfter(deadline: deadline, execute: dispatchWorkItem)

    return dispatchWorkItem
  }
}
