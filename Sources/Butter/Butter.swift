import Foundation
import UIKit

extension Butter {
  private struct Instance {
    let window: ButterWindow
    let toastViewController: ToastViewController
  }
}

public class Butter {
  private static var instanceByScene = [UIWindowScene: Instance]()

  /// Connects a scene to Butter.
  ///
  /// This should be called when a scene will connect to your app.
  public static func connect(_ windowScene: UIWindowScene) {
    guard instanceByScene[windowScene] == nil else { return }

    let window = ButterWindow(windowScene: windowScene)
    let toastViewController = ToastViewController()

    toastViewController.rootViewController = windowScene.windows.first?.rootViewController

    window.windowLevel = .alert
    window.rootViewController = toastViewController
    window.makeKeyAndVisible()

    instanceByScene[windowScene] = .init(window: window, toastViewController: toastViewController)
  }

  /// Disconnects a scene from butter.
  ///
  /// This should be called when a scene did disconnect from your app.
  public static func disconnect(_ windowScene: UIWindowScene) {
    instanceByScene[windowScene] = nil
  }

  /// Enqueues a toast. If a toast with the given toast's ID is currently presented or enqueued, it will be modified.
  /// - Parameters:
  ///   - toast: The toast to enqeueue.
  ///   - windowScene: The window scene. This only needs to be specified in multiple window apps.
  public static func enqueue(_ toast: Toast, on windowScene: UIWindowScene? = nil) {
    guard let instance = self.instance(for: windowScene) else { return }

    instance.toastViewController.enqueue(toast)
  }

  /// Dismisses the toast with the given ID. If a toast with the given toast's ID is enqueued, it will be dequeued.
  /// - Parameters:
  ///   - id: The ID of the toast.
  ///   - windowScene: The window scene. This only needs to be specified in multiple window apps.
  public static func dismiss(id: UUID, from windowScene: UIWindowScene? = nil) {
    guard let instance = self.instance(for: windowScene) else { return }

    instance.toastViewController.dismiss(id: id)
  }

  /// The foreground active window scene.
  public static var foregroundActiveWindowScene: UIWindowScene? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
      .first
  }

  private static func instance(for windowScene: UIWindowScene? = nil) -> Instance? {
    let windowScene = windowScene ?? foregroundActiveWindowScene

    if let windowScene = windowScene {
      return instanceByScene[windowScene]
    } else {
      return nil
    }
  }

  private init() {}
}
