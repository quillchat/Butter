# 🧈 Butter

An iOS toast framework.

## Styles

Toasts come in three styles:

* Standard
* Indeterminate
* Progress

### Standard

To enqueue a standard toast:

```swift
Butter.enqueue(.init(title: "This is a toast"))
```

To enqueue a standard toast with a subtitle:

```swift
Butter.enqueue(.init(title: "This is a toast", subtitle: "Hello"))
```

### Indeterminate

An indeterminate toast is one that includes a `UIActivityIndicator` (an indeterminate spinner). To enqueue an indeterminate toast:

```swift
let id = UUID()
Butter.enqueue(.init(id: id, title: "Please wait…", style: .indeterminate))
```

Indeterminate toasts are not automatically dismissed. You dismiss a toast by specifying its ID. For example:

```swift
Butter.dismiss(id: id)
```

If a toast with the given ID is presented, it will be dismissed. If it is enqueued, it will be dequeued.

### Progress

A progress toast is one that includes a circular progress indicator. A progress toast is automatically dismissed once its progress is finished. To enqueue a progress toast:

```swift
let progress = getProgress()
Butter.enqueue(.init(title: "Uploading…", style: .progress(progress)))
```

You can optionally provide a tint color for the progress indicator:

```swift
Butter.enqueue(.init(title: "Uploading…", style: .progress(progress, tintColor: .systemRed)))
```

## Appearance

Toasts come in two appearances:

* Standard
* Error

To enqueue a toast indicating that an error has occurred:

```swift
Butter.enqueue(.init(title: "Upload Failed", appearance: .error))
```

## Tap Actions

It is possible to specify a tap action for any toast. For example:

```swift
Butter.enqueue(.init(
  title: "Task Complete", 
  subtitle: "Tap to View", 
  onTap: { self.presentTask() }))
```

Whether or not a tap action is specified, a standard toast will always dismiss itself on tap.

## Modifying a Toast

If you enqueue a Toast with the same ID as an existing toast (either presented or enqueued), that Toast will be replaced.

## Bottom Inset

Toasts are inset from bottom of the screen according to the safe area inset of the top-most view controller. This offset can be overridden by implementing the `BottomInsetProviding` protocol.

The top-most view controller is determined by traversing the `presentedViewController` hierarchy, stepping into the `topViewController` of any `UINavigationController` and the `selectedViewController` of any `UITabBarController`. A view controller may not become the  `topViewController` if:

* It has a `modalPresentationStyle` of `.popover`.
* It has a `modalPresentationStyle` of `.pageSheet` or `.formSheet` in a  regular-height, regular-width size class.
* It is a `UIAlertController`.

## Multiple Window Apps

You can specify the window scene on which the toast should appear. If the toast should appear over a particular view:

```swift
Butter.enqueue(.init(title: "Toast"), on: view.window.windowScene)
```

If a window scene isn't specified, the toast will appear over the foreground active window scene.
