# 🧈 Butter

An iOS toast framework.

## Styles

Toasts come in four styles:

* Standard
* Image
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

### Image

To enqueue a image toast:

```swift
let image: UIImage = someUIImage()
Butter.enqueue(.init(title: "An image!", style: .image(image)))
```

By default, the image is masked to a circle with a radius of 12pt. This can be disabled:

```swift
Butter.enqueue(.init(
  title: "An unmasked image!", 
  style: .image(image, shouldMaskToCircle: false)))
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
let progress: Progress = getProgress()
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

If you enqueue a toast with the same ID as an existing toast (either presented or enqueued), that toast will be replaced.

## Screen Edge

Toasts are inset according to the safe area inset of the top-most view controller. The top-most view controller is determined by traversing the `presentedViewController` hierarchy, stepping into the `topViewController` of any `UINavigationController` and the `selectedViewController` of any `UITabBarController`.

A view controller may *not* become the top-most view controller if:

* It has a `modalPresentationStyle` of `.popover`.
* It has a `modalPresentationStyle` of `.pageSheet` or `.formSheet` in a  regular-height, regular-width size class.
* It is a `UIAlertController`.

By default, toasts appear from the bottom edge of the screen. To present a toast from the top edge, specify the edge property:

```swift
Butter.enqueue(.init(title: "Message Sent", edge: .top))
```

The top-most view controller can override the bottom inset by implementing the `BottomInsetProviding` protocol.

## Multiple Window Apps

By default, toasts appear in the first foreground active window scene. You can optionally specify the window scene in which the toast should appear. For example, if a toast should appear in the same scene as a particular view:

```swift
Butter.enqueue(.init(title: "Toast"), on: view.window.windowScene)
```

## Known Issues

Toasts follow the user interface orientation of the top-most view controller. If a toast is visible when the top-most view controller changes to one with a different orientation, the debug console will display an `Unbalanced calls to begin/end appearance transitions for Butter.ButterViewController` error.