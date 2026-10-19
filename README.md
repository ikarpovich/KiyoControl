<h1 align="center"> KiyoControl </h1>

<!-- subtext -->
<div align="center">
Control your cameras settings without using the software provided (or not) by the company.
</div>

<br/>

<!-- shields -->
<div align="center">
    <!-- license -->
    <a href="https://github.com/ikarpovich/KiyoControl/blob/master/LICENSE">
        <img src="https://img.shields.io/github/license/ikarpovich/KiyoControl.svg" alt="license"/>
    </a>
    <!-- platform -->
    <a href="https://github.com/ikarpovich/KiyoControl">
        <img src="https://img.shields.io/badge/platform-macOS%2026%2B-lightgrey.svg" alt="platform"/>
    </a>
    <!-- swift version -->
    <a href="https://github.com/ikarpovich/KiyoControl">
        <img src="https://img.shields.io/badge/swift-6-orange.svg" alt="swift 6"/>
    </a>
    <!-- upstream -->
    <a href="https://github.com/itaybre/CameraController">
        <img src="https://img.shields.io/badge/forked%20from-itaybre%2FCameraController-blue.svg" alt="forked from itaybre/CameraController"/>
    </a>
</div>

<br/>

## About this fork

KiyoControl is a fork of [itaybre/CameraController](https://github.com/itaybre/CameraController) re-targeted at Apple Silicon, macOS 26 (Tahoe), Swift 6, and the Liquid Glass design language, with first-class support for the Razer Kiyo Pro vendor controls. It remains under GPL v3, the same license as the upstream project. KiyoControl is not affiliated with, endorsed by, or sponsored by Razer.

### What changed since the fork point

#### Toolchain & architecture
- **Swift 6 + macOS 26 deployment target.** Strict concurrency mode (`SWIFT_STRICT_CONCURRENCY = complete`) plus warnings-as-errors (`SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`) on the app and helper targets; build is clean at 0 warnings, 0 SwiftLint violations.
- **SwiftUI `App` entry.** Replaced `@NSApplicationMain` with `@main struct` and a dedicated `Settings { ... }` scene driven via `@NSApplicationDelegateAdaptor`.
- **`@Observable` macro everywhere.** Every model class migrated from Combine `ObservableObject` / `@Published` to the Observation framework; views use `@Bindable` / `@Environment`. Removes the "Publishing changes from within view updates" runtime warning class entirely.
- **`UVCDeviceActor` for race-free hardware I/O.** All UVCControl reads and writes funneled through a per-device `actor`. Slider drags can no longer interleave their underlying USB control transfers. `nonisolated(unsafe)` escape hatches reduced to six well-commented sites (CFUUID constants + AVCaptureDevice equality), with unit tests covering write-serialization.
- **`PreviewSession` isolation.** A `@MainActor @Observable` type owns the entire `AVCaptureSession` lifecycle (configure / attach / detach / change-quality / suspend / resume); blocking `start/stopRunning` calls are dispatched onto a dedicated serial queue so the main actor stays responsive on cold-camera startup.
- **Login item via `SMAppService`.** Migrated off the deprecated `SMLoginItemSetEnabled` API.
- **Camera permission deferred.** Permission prompt now fires lazily on the first `PreviewSession.attach`, not at app launch.

#### UI rewrite
- **Settings rebuilt around `Form` + `Section` + `LabeledContent`.** Native HIG layout replaces the prior hand-built `SectionView` / `SectionTitle` / `GenericControl` / custom `Slider` & `Toggle` / `AutoBadge` / `TabSelectorView` / `VisualEffectView` scaffolding (all eight files removed).
- **Menu-bar popover with the macOS 26 Liquid Glass arrow tail.** Migrated through `MenuBarExtra(.window)` and back to `NSStatusItem` + `NSPopover` once it became clear no SwiftUI `MenuBarExtraStyle` exposes the popover-arrow chrome on macOS 26. Drag-to-detach, transient dismiss, and Liquid Glass material are all native.
- **Native segmented `Picker` navigation.** Top-of-popover section switcher driven by a `@State Section` enum + `@ViewBuilder switch`, replacing the SwiftUI `TabView` chrome that didn't sit cleanly inside an NSPopover.
- **Auto-toggle reveal pattern.** Exposure / Focus / White Balance / Hue rows have a header row with the feature label and the native Auto switch; manual sliders expand below as labelled child rows when Auto is off.
- **Camera name header above the preview frame.** Squared corners (no rounded clip) so it sits flush against the popover edges.
- **Profile row uses an ellipsis Menu** (Apply / Delete) instead of hover-revealed icons; profile list is a fixed-height `List` so popover height stays stable.
- **Slider step granularity.** New `tickStep = max(resolution, span / 10)` on `NumberCaptureDeviceProperty` and `MultipleCaptureDeviceProperty` so sliders snap to ~10 detents instead of single-unit precision over hundreds-wide ranges.

#### Razer Kiyo Pro vendor controls
- Autofocus mode: Responsive and Passive.
- HDR on/off and Dark/Bright HDR mode.
- Field of View: Wide, Medium, and Narrow.
- Vendor protocol: sends eight-byte ISP commands through the Kiyo Pro extension unit (GUID 23e49ed0-1178-4f31-ae52-d2fb8a8d3b48), including the required setup commands for Medium/Narrow FoV and the save command.
- Command values follow the public [kiyoproctrls-mac](https://github.com/johnteslade/kiyoproctrls-mac) utility and its [Linux predecessor](https://github.com/soyersoyer/kiyoproctrls).
- Readback limitation: the camera does not report these values through the available GET request. The UI starts each control as Not set and shows values applied successfully during the current session.
- VC Extension Unit descriptor parsing is kept as an independent pass so the Kiyo unit ID is discovered instead of hard-coded.

#### Project hygiene
- **Renamed `CameraController` → `KiyoControl`** (Xcode project, target, scheme, source/test directories, bundle identifiers `me.karpovich.KiyoControl{,.Helper}`, Info.plist `CFBundleDisplayName`).
- **Xcode 26 project-format upgrade**, predictable PBX file IDs replaced with random 24-hex IDs, swiftlint complexity / function-body-length violations resolved structurally (helper extraction in `IOUSBConfigurationDescriptorPtr+UVC.swift`, `Snapshots` struct in `DeviceController.swift`).

## Building from source

KiyoControl is currently source-only — there are no published binaries, no signed release `.zip`, and no Homebrew cask. Build it locally with:

### Required

- macOS 26 (Tahoe) or later
- Xcode 26 or later
- [SwiftLint](https://github.com/realm/SwiftLint) (used as a Run Script build phase)

```sh
git clone https://github.com/ikarpovich/KiyoControl.git
cd KiyoControl
xcodebuild -scheme KiyoControl -configuration Release build
```

Or open `KiyoControl.xcodeproj` in Xcode and run.

## FAQ

- **Does it work with Apple's FaceTime camera?**
  On older Intel Macs without the T1/T2 chip it will work; T1/T2/Apple Silicon FaceTime cameras require a special entitlement only available to Apple.

## Support
- **macOS 26 (Tahoe)** only. The deployment target is `26.0` so the codebase can use Swift 6 strict concurrency, the Observation framework, the macOS 26 Liquid Glass APIs (`GlassEffectContainer`, `.glassEffect()`), `SMAppService`, and the modern `MenuBarExtra` / `NSPopover` chrome unconditionally.
- Works with any camera controllable via [UVC](https://www.usb.org/document-library/video-class-v15-document-set), with Razer Kiyo Pro autofocus mode, HDR, HDR mode, and Field of View controls.

## Contributors
- [@ikarpovich](https://github.com/ikarpovich) (KiyoControl fork maintainer)
- [@itaybre](https://github.com/itaybre) (upstream CameraController author)
- Icons by [@herrerajeff](https://github.com/herrerajeff)
