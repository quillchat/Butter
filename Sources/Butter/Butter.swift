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

  private static var didDisconnectObserver: NSObjectProtocol?

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
    guard let windowScene = windowScene ?? UIApplication.shared.currentWindowScene else { return nil }

    if let instance = instanceByScene[windowScene] {
      return instance
    }

    connect(windowScene)

    return instanceByScene[windowScene]
  }

  private static func connect(_ windowScene: UIWindowScene) {
    guard instanceByScene[windowScene] == nil else { return }

    instanceByScene[windowScene] = makeInstance(for: windowScene)

    if didDisconnectObserver == nil {
      // Start observing disconnections
      didDisconnectObserver = NotificationCenter.default.addObserver(
        forName: UIWindowScene.didDisconnectNotification,
        object: nil,
        queue: nil) { notification in

        if let windowScene = notification.object as? UIWindowScene {
          self.disconnect(windowScene)
        }
      }
    }
  }

  private static func disconnect(_ windowScene: UIWindowScene) {
    instanceByScene[windowScene] = nil
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
