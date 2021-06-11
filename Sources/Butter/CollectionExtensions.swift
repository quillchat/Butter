import Foundation

extension Collection where Element: Identifiable {
  func contains(id: Element.ID) -> Bool {
    contains { $0.id == id }
  }

  func first(withID id: Element.ID) -> Element? {
    return first { $0.id == id }
  }

  func firstIndex(withID id: Element.ID) -> Self.Index? {
    firstIndex { $0.id == id }
  }
}
