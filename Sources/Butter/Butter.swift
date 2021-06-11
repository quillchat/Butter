import Foundation
import UIKit

extension Butter {
  private struct Instance {
    let window: ButterWindow
    let butterViewController: ButterViewController
  }
}

public class Butter {
  private static var instanceByScene = [UIWindowScene: Instance]()

  /// Connects a scene to Butter.
  ///
  /// This should be called when a scene will connect to your app.
  public static func connect(_ windowScene: UIWindowScene) {
    guard instanceByScene[windowScene] == nil else { return }

    instanceByScene[windowScene] = makeInstance(for: windowScene)
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

    instance.butterViewController.enqueue(toast)
  }

  /// Dismisses the toast with the given ID. If a toast with the given toast's ID is enqueued, it will be dequeued.
  /// - Parameters:
  ///   - id: The ID of the toast.
  ///   - windowScene: The window scene. This only needs to be specified in multiple window apps.
  public static func dismiss(id: UUID, from windowScene: UIWindowScene? = nil) {
    guard let instance = self.instance(for: windowScene) else { return }

    instance.butterViewController.dismiss(id: id)
  }

  private static func instance(for windowScene: UIWindowScene? = nil) -> Instance? {
    guard let windowScene = windowScene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      return nil
    }

    if let instance = instanceByScene[windowScene] {
      return instance
    }

    let instance = makeInstance(for: windowScene)

    instanceByScene[windowScene] = instance

    return instance
  }

  private static func makeInstance(for windowScene: UIWindowScene) -> Instance {
    let window = ButterWindow(windowScene: windowScene)
    let butterViewController = ButterViewController()

    butterViewController.rootViewController = windowScene.windows.first?.rootViewController

    window.windowLevel = .alert
    window.rootViewController = butterViewController
    window.makeKeyAndVisible()

    return .init(window: window, butterViewController: butterViewController)
  }

  private init() {}
}
