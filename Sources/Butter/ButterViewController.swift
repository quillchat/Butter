import Foundation
import UIKit

extension ButterViewController {
  private struct Item {
    let toastView: ToastView
    var dismissDispatchWorkItem: DispatchWorkItem?
    var bottomInset: CGFloat
    var onTap: (() -> Void)?
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
      guard let currentItem = self.currentItem else { return }

      let bottomInset = self.bottomInset()

      guard currentItem.bottomInset != bottomInset else { return }

      self.currentItem!.bottomInset = bottomInset

      currentItem.toastView.snp.updateConstraints { make in
        make.bottom.equalTo(self.view.snp.bottom).inset(self.currentItem!.bottomInset)
      }

      UIView.animate(withDuration: 0.3) {
        currentItem.toastView.superview?.layoutIfNeeded()
      }
    })
  }

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

    let bottomInset = bottomInset()

    toastView.snp.makeConstraints { make in
      make.bottom.equalTo(self.view.snp.bottom).inset(bottomInset)
      make.left.greaterThanOrEqualToSuperview().inset(16)
      make.right.lessThanOrEqualToSuperview().inset(16)
      make.centerX.equalToSuperview()
    }

    toastView.alpha = 0
    toastView.transform = CGAffineTransform.init(scaleX: 0.3, y: 0.3)

    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: []) {
      toastView.transform = CGAffineTransform.identity
    }

    UIView.animate(withDuration: 0.3) {
      toastView.alpha = 1
    }

    currentItem = Item(
      toastView: toastView, dismissDispatchWorkItem: makeDismissDispatchWorkItem(for: toast), bottomInset: bottomInset)
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

    UIView.animate(withDuration: Self.fadeDuration, animations: {
      currentItem.toastView.alpha = 0
    }, completion: { [weak self] _ in
      guard let weakSelf = self else { return }

      weakSelf.currentItem = nil

      currentItem.toastView.removeFromSuperview()

      if !weakSelf.queue.isEmpty {
        weakSelf.dequeue()
      }
    })
  }

  private func bottomInset() -> CGFloat {
    // Walk the view hierarchy of the rootViewController to determine the top-most view. Use that view's safeAreaInset
    // to determine the bottom inset of the toast.
    guard let rootViewController = self.rootViewController else { return Self.bottomInset }

    var viewController = rootViewController.topViewController { viewController in
      if viewController.modalPresentationStyle == .popover { return false }

      if viewController.traitCollection.horizontalSizeClass == .regular &&
        viewController.traitCollection.verticalSizeClass == .regular {

        if viewController.modalPresentationStyle == .pageSheet ||
          viewController.modalPresentationStyle == .formSheet { return false }
      }

      if viewController is UIAlertController { return false }

      return true
    }

    if let tabBarController = viewController as? UITabBarController,
      let selectedViewController = tabBarController.selectedViewController {

      viewController = selectedViewController
    }

    return viewController.view.safeAreaInsets.bottom + Self.bottomInset
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
