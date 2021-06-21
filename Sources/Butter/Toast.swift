import Foundation
import UIKit

/// The appearance of the toast.
public enum Appearance: Hashable {
  /// The standard appearance.
  case standard

  /// An appearance that indicates that an error has occurred.
  case error
}

/// The style of the toast.
public enum Style: Hashable {
  /// A toast that is automatically dismissed after a short period of time.
  case standard

  /// A toast that includes an indeterminate progress indicator. This toast is not automatically dismissed.
  case indeterminate

  /// A toast that includes a circular progress indicator. The toast is automatically dismissed when the progress
  /// `isFinished`.
  case progress(Progress, tintColor: UIColor? = nil)
}

/// The screen edge that a toast appears on.
public enum Edge: Hashable {
  /// The top of the screen.
  case top

  /// The bottom of the screen. Toasts are inset from bottom of the screen according to the safe area inset of the
  /// top-most view controller. This offset can be overridden by implementing the
  /// [BottomInsetProviding](x-source-tag://BottomInsetProviding) protocol.
  case bottom
}

public struct Toast: Identifiable {
  private static let duration: TimeInterval = 3

  public var id: UUID

  /// The title of the toast.
  public var title: String

  /// The optional subtitle of the toast.
  public var subtitle: String?

  /// The appearance of the toast.
  public var appearance: Appearance

  /// The style of the toast.
  public var style: Style

  /// The screen edge that the toast appears on.
  public var edge: Edge

  /// The optional action to perform when the toast is tapped.
  public var onTap: (() -> Void)?

  /// Creates a toast.
  /// - Parameters:
  ///   - id: The ID of the toast.
  ///   - title: The title of the toast.
  ///   - subtitle: The optional subtitle.
  ///   - appearance: The appearance of the toast.
  ///   - style: The style of the toast.
  ///   - edge: The screen edge that the toast appears on.
  ///   - onTap: The optional action to perform when the toast is tapped.
  public init(
    id: UUID = UUID(),
    title: String,
    subtitle: String? = nil,
    appearance: Appearance = .standard,
    style: Style = .standard,
    edge: Edge = .bottom,
    onTap: (() -> Void)? = nil) {

    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.appearance = appearance
    self.style = style
    self.edge = edge
    self.onTap = onTap
  }

  /// Indicates whether the toast should be dismissed when tapped.
  ///
  /// Returns `true` for `.standard` toasts. Returns `false` for `.indeterminate` toasts. Returns `true` for `.progress`
  /// toasts if the progress `isFinished`, false otherwise.
  public var shouldDismissWhenTapped: Bool {
    switch style {
    case .standard:
      return true
    case .indeterminate:
      return false
    case let .progress(progress, _):
      return progress.isFinished
    }
  }

  /// Returns the duration after which the toast should be dismissed. A nil value indicate that the toast is not
  /// automatically dismissed.
  public var duration: TimeInterval? {
    switch style {
    case .standard:
      return Self.duration
    case .indeterminate:
      return nil
    case let .progress(progress, _):
      return progress.isFinished ? Self.duration : nil
    }
  }
}
