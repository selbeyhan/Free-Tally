# Free Tally

A simple, fast, fully local tally counter app for iOS. Create as many counters as you
want, tap the screen to count up, and — the main trick — count using your **volume
buttons** without the volume actually changing or the system volume HUD popping up.

Everything is 100% on-device. There's no account, no backend, no analytics SDK, and no
network code anywhere in the project. Counters are stored as a single JSON file in the
app's sandboxed Documents directory; settings live in `UserDefaults`. Nothing ever
leaves the phone.

## Features

- **Multiple counters** — each with its own name, color, SF Symbol icon, and step size
  (count by 1, 5, 10, whatever you like).
- **Volume-button counting** — press either volume button while a counter is open to
  add to it. The system volume itself never actually moves and the volume HUD never
  appears (see [How it works](#how-volume-button-counting-works) below).
- **Tap-to-count** — tap anywhere on a counter's screen to increment; a `−` button to
  correct mistakes and an undo button to step back through recent changes.
- **Reset / delete / rename / recolor** any counter at any time.
- **Reorder & swipe-to-delete** on the counter list.
- **Haptic feedback**, an optional **keep-screen-awake** mode, and full support for
  Dynamic Type / VoiceOver / Dark Mode.
- **Erase All Data** in Settings, for a clean slate.
- No permissions requests at all — the app doesn't need the camera, microphone, or
  network access for any of this.

## Requirements

- A Mac with **Xcode 15+** (targets iOS 17+; that's what the `@Observable` /
  `NavigationStack` / `ContentUnavailableView` APIs the app uses need).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the `.xcodeproj` from
  `project.yml` (the project file itself isn't checked in, so it always matches the
  source layout).

```sh
brew install xcodegen
```

## Getting started

```sh
cd TallyCounter
xcodegen generate
open TallyCounter.xcodeproj
```

Then in Xcode:

1. Select the **TallyCounter** scheme.
2. If you're running on a physical device, pick your team under
   *Signing & Capabilities* (the app has no capabilities/entitlements otherwise).
3. Choose a simulator or your device and hit **Run**.

Run the test suite with **Cmd+U**, or from the command line:

```sh
xcodebuild test -scheme TallyCounter -destination 'platform=iOS Simulator,name=iPhone 15'
```

## How volume-button counting works

iOS doesn't expose a public API to intercept hardware volume button presses directly.
The app uses the standard workaround: it activates an ambient `AVAudioSession`, parks
an invisible `MPVolumeView` in the window (which is what suppresses the system volume
HUD), and observes the session's `outputVolume` via KVO. Each physical button press
changes `outputVolume` by one step, which fires the observer; the app then immediately
snaps the volume back to the middle of its range so the next press — up or down — keeps
producing a fresh, detectable change instead of getting stuck at 0% or 100%.

This only runs while a counter's detail screen is open and the app is in the
foreground, and it can be turned off entirely in Settings if you'd rather it not touch
the audio session at all.

**Heads up on the App Store:** Apple's review guidelines restrict volume buttons to
volume control (and camera shutter, for camera apps). An app that repurposes them for
something like tallying can be rejected during App Store review. This is completely
fine for personal use, sideloading, or TestFlight, but keep it in mind if you ever plan
to submit this to the public App Store — you'd likely want to ship with the toggle
defaulted off, or drop the feature, for that build.

## Project layout

```
TallyCounter/
  project.yml                  XcodeGen spec (generates the .xcodeproj)
  Sources/
    App/                       App entry point
    Models/                    Counter, AppSettings
    Store/                     CounterStore — local persistence + business logic
    Services/                  VolumeButtonHandler, HapticsManager
    Views/                     SwiftUI screens
    Extensions/                Color(hex:)
  Resources/
    Assets.xcassets/           App icon, accent color
  Tests/
    TallyCounterTests/         Unit tests for CounterStore
```
