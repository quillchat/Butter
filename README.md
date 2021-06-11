# Butter

An iOS toast framework.

## Usage

Add the following to your `UIWindowSceneDelegate`:

```swift
func scene(
  _ scene: UIScene, 
  willConnectTo session: UISceneSession, 
  options connectionOptions: UIScene.ConnectionOptions) {
  
  if let windowScene = scene as? UIWindowScene {
    Butter.connect(windowScene)
  }

func sceneDidDisconnect(_ scene: UIScene) {
  if let windowScene = scene as? UIWindowScene {
    Butter.disconnect(windowScene)
  }
}
``` 

### Styles

Toasts come in three styles:

* Standard
* Indeterminate
* Progress

**Standard**

To enqueue a standard toast:

```swift
Butter.enqueue(.init(title: "This is a toast"))
```

To enqueue a standard toast with a subtitle:

```swift
Butter.enqueue(.init(title: "This is a toast", subtitle: "Hello"))
```

**Indeterminate**

An indeterminate toast is one that includes a `UIActivityIndicator` (an indeterminate spinner). To enqueue an indeterminate toast:

```swift
let id = UUID()
Butter.enqueue(.init(id: id, title: "Please wait…", style: .indeterminate))
```

Indeterminate toasts are not automatically dismissed. You dismiss a toast by specifying it's ID. For example:

```swift
Butter.dismiss(id: id)
```

If a toast with the given ID is presented, it will be dismissed. If it is enqueued, it will be dequeued.

**Progress**

A progress toast is one that includes a circular progress indicator. A progress toast is automatically dismissed once its progress is finished. To enqueue a progress toast:

```swift
let progress = getProgress()
Butter.enqueue(.init(title: "Uploading…", style: .progress(progress)))
```

### Appearance

Toasts come in two appearances:

* Standard
* Error

To enqueue a toast indicating that an error has occurred:

```swift
Butter.enqueue(.init(title: "Upload Failed", appearance: .error))
```

### Tap Actions

It is possible to specify a tap action to any toast. For example:

```swift
Butter.enqueue(.init(
  title: "Task Complete", 
  subtitle: "Tap to View", 
  onTap: { self.presentTask() }))
```

### Modifying a Toast

If you enqueue a Toast with the same ID of an existing toast (either presented or enqueued), that Toast will be replaced.
