# Contraster

A fast, lightweight macOS menu bar utility for checking colour contrast. Pick two colours from anywhere on your screen and instantly see the contrast ratio plus WCAG 2.x AA and AAA compliance for large text, small text, and graphical elements.

Contraster runs from the menu bar (there is no Dock icon). Screen content is only read to sample individual pixel colours — nothing is stored or transmitted.

## Using the app

### First launch

On first run, Contraster shows a welcome tutorial. The first step asks for **Screen Recording** permission, which macOS requires before any app can read pixel colours from the display. Contraster only samples the pixels you click; it does not record or send screen content.

Once permission is granted, the tutorial walks through the rest of the workflow. You can reopen it anytime from the menu bar (see below).

### Picking colours

1. Click the **colour picker icon** in the menu bar to open the popover.
2. Click **New pick**.
3. Click anywhere on screen to select the **first colour**.
4. Click again to select the **second colour**.

While picking, a magnified loupe follows the cursor so you can target precise pixels. Press **Esc** to cancel, or use the **Cancel** button in the popover. Scroll up and down to zoom in/out for precision picking.

### Reading results

After both colours are picked, the popover shows:

- The **contrast ratio** (for example, `4.52:1`)
- **WCAG compliance** for large text, small text, and graphical elements (pass/fail at AA and AAA levels)

Previous picks are kept in the **History** section. Hover a history row and click the trash icon to delete it.

### Menu bar controls

- **Left-click** the menu bar icon — open or close the popover.
- **Hold option (⌥) and Left-click** the menu bar icon — open the popover and start capturing immediately.
- **Right-click** the menu bar icon (or click the gear icon inside the popover) — open the menu:
  - About Contraster
  - Show tutorial
  - Send feedback
  - Quit Contraster

## Running locally

### Requirements

- macOS 12.3 or later
- Xcode (recent version recommended)

### Clone and run

```bash
git clone git@github.com:georgegillams/contraster.git
cd contraster
open Contraster.xcodeproj
```

In Xcode:

1. Select the **Contraster** scheme.
2. Choose **My Mac** as the run destination.
3. Press **Run** (⌘R).

The app builds and launches from Xcode. Look for the Contraster icon in the menu bar.

### Schemes

| Scheme                 | Use when                                                                                     |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| **Contraster**         | Normal development and testing the first-run experience (welcome tutorial, permission flow). |
| **G_DEBUG Contraster** | Automatically opens the popover and starts a new pick on launch, and enables debug logs.     |

No third-party dependencies are required — open the project and build.

### Local development vs production builds

When you **Run** from Xcode, the app uses the **Debug** build configuration. When you **Archive** for the App Store, it uses **Release**. Several deliberate differences make it easy to tell the two apart and stop them interfering with each other.

|                               | Local development (Debug)                   | Production (Release / App Store)           |
| ----------------------------- | ------------------------------------------- | ------------------------------------------ |
| App bundle on disk            | `Contraster Local.app`                      | `Contraster.app`                           |
| Bundle identifier             | `uk.co.georgegillams.Contraster.local`      | `uk.co.georgegillams.Contraster`           |
| Display name                  | `Contraster (Local)`                        | `Contraster`                               |
| Menu build line               | `Contraster local development`              | `Contraster {version}` (marketing version) |
| Screen Recording entry        | **Contraster Local**                        | **Contraster**                             |
| Debug logging (`gDebugPrint`) | Enabled when running the **G_DEBUG** scheme | Compiled out                               |
| Sandbox / app data            | Separate container                          | App Store container                        |

Archiving always uses **Release**, so a normal archive produces the production app name, bundle ID, and version label. The local-only settings exist only in the Debug configuration in `Contraster.xcodeproj`.

#### How each difference is implemented

**App name and bundle identifier**

Set per build configuration in `Contraster.xcodeproj/project.pbxproj`:

- **Debug:** `PRODUCT_NAME = "Contraster Local"` and `PRODUCT_BUNDLE_IDENTIFIER = uk.co.georgegillams.Contraster.local`
- **Release:** `PRODUCT_NAME = "$(TARGET_NAME)"` (→ `Contraster`) and `PRODUCT_BUNDLE_IDENTIFIER = uk.co.georgegillams.Contraster`

macOS treats different bundle IDs as different apps. That gives local and production builds separate Screen Recording permissions, separate sandbox containers (Core Data, preferences), and separate Launch at Login entries.

**Display name and Screen Recording usage string**

Debug-only Info.plist keys in the same Debug build configuration:

- `INFOPLIST_KEY_CFBundleDisplayName = "Contraster (Local)"`
- `INFOPLIST_KEY_CFBundleName = "Contraster Local"`
- `INFOPLIST_KEY_NSScreenCaptureUsageDescription` — local-specific permission prompt text

Release builds inherit the defaults from `Contraster/Trunk/Info.plist` and generated Info.plist keys.

**Menu build line (`local development` vs version)**

`Contraster/Utils/Bundle+Version.swift` defines `menuBuildLabel`, which returns `"local development"` when `isLocalDevelopment` is true. That flag is `#if DEBUG` — true only in Debug builds, false in Release regardless of how the app was installed.

`AppDelegate.openMenu()` uses `Bundle.main.menuBuildLabel` for the footer item (e.g. `Contraster local development` or `Contraster 1.2`).

**Debug logging**

``Software Chording Keyboard/Models/Debug.swift` wraps `gDebugPrint` in `#if DEBUG` and only prints when the `G_DEBUG` launch argument is present (`isGDebugScheme`). Use the **G_DEBUG Software Chording Keyboard** scheme to see log output; the normal Debug scheme compiles logging support but stays quiet.

**G_DEBUG Contraster scheme**

The **G_DEBUG Contraster** scheme is separate from the local/production split. It passes the `G_DEBUG` launch argument (see `Contraster.xcodeproj/xcshareddata/xcschemes/G_DEBUG Contraster.xcscheme`). `isGDebugScheme` in `Debug.swift` checks for that argument and, in `AppDelegate`, triggers an automatic popover + pick on launch. Both schemes still build the Debug configuration when you Run.

**Resetting the welcome tutorial (development)**

Hold **Option (⌥)** while opening the menu to reveal **Reset welcome tutorial done**. This clears the `firstWelcomeDone` flag in Core Data (`ColorPairStore.resetFirstWelcomeDone()`), so the first-run tutorial appears again on next launch. The item is always gated on the Option modifier in `AppDelegate.openMenu()`; it is intended for testing the onboarding flow locally.

## Screen Recording permission during development

Contraster needs Screen Recording permission to capture pixel colours. Local and production builds require **separate** permission grants because they use different bundle identifiers (see above).

### Granting permission

1. Launch the app from Xcode.
2. When prompted, click **Grant permissions** in the welcome tutorial, or go to **System Settings → Privacy & Security → Screen Recording**.
3. Enable the toggle for **Contraster Local** (not the App Store **Contraster** entry).

If macOS does not show a prompt, open Screen Recording settings manually — the tutorial’s **Manage permissions** button does this, or use the deep link from the app.

### Tips when permission does not work

**Enable the correct entry.** When running from Xcode, grant permission to **Contraster Local**. The App Store build (**Contraster**) is a separate entry and permission on one does not apply to the other.

**The system prompt only appears once per app session if denied.** If you dismissed it, grant access manually in System Settings instead of waiting for another dialog.

**Restart the app after changing permission.** Quit Contraster completely (menu bar → Quit, or stop the run in Xcode) and launch again so macOS applies the new setting.

**Toggle permission off and on.** If picking still returns wrong or blank colours after granting access, remove the app from the Screen Recording list, rebuild and run, then re-enable it.

**Reset TCC state while iterating on permissions.** During development you can clear Screen Recording consent and start fresh:

```bash
# Local development build (Xcode Run)
tccutil reset ScreenCapture uk.co.georgegillams.Contraster.local

# App Store / production build
tccutil reset ScreenCapture uk.co.georgegillams.Contraster
```

Then rebuild, run, and grant permission again through the tutorial or System Settings.

**Use the right scheme for what you are testing.** To verify the permission onboarding flow, run the **Contraster** scheme. Use **G_DEBUG Contraster** when you already have permission and want to jump straight into picking.

### What Contraster accesses

The app is sandboxed. Screen capture is governed by macOS privacy (TCC): users grant **Screen Recording** in System Settings. Contraster uses that only to read the colour at the cursor position during a pick. See `Contraster/Trunk/Info.plist` for the usage description shown to users.

## License

MIT — see [LICENSE](LICENSE).

## Release

- Update version (marketing version) and build (needs incrementing). In XCode, click Contraster -> General -> Identity -> Version/Build
- Take screenshots at 1280x800
- Clean
- Create build online at https://appstoreconnect.apple.com/
- Select non-debug scheme
- Archive
- Upload
