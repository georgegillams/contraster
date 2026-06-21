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

| Scheme               | Use when                                                                                     |
| -------------------- | -------------------------------------------------------------------------------------------- |
| **Contraster**       | Normal development and testing the first-run experience (welcome tutorial, permission flow). |
| **DEBUG Contraster** | Automatically opens the popover and starts a new pick on launch, and enables debug logs.     |

No third-party dependencies are required — open the project and build.

## Screen Recording permission during development

Contraster needs Screen Recording permission to capture pixel colours. This applies to release builds and to debug builds run from Xcode.

### Granting permission

1. Launch the app from Xcode.
2. When prompted, click **Grant permissions** in the welcome tutorial, or go to **System Settings → Privacy & Security → Screen Recording**.
3. Enable the toggle for **Contraster**.

If macOS does not show a prompt, open Screen Recording settings manually — the tutorial’s **Manage permissions** button does this, or use the deep link from the app.

### Tips when permission does not work

**The app may appear under different names in Screen Recording.** Debug builds sometimes show as `Contraster` and sometimes with a path under Xcode’s DerivedData folder. Enable whichever entry corresponds to the build you are currently running.

**The system prompt only appears once per app session if denied.** If you dismissed it, grant access manually in System Settings instead of waiting for another dialog.

**Restart the app after changing permission.** Quit Contraster completely (menu bar → Quit, or stop the run in Xcode) and launch again so macOS applies the new setting.

**Toggle permission off and on.** If picking still returns wrong or blank colours after granting access, remove Contraster from the Screen Recording list, rebuild and run, then re-enable it.

**Reset TCC state while iterating on permissions.** During development you can clear the app’s Screen Recording consent and start fresh:

```bash
tccutil reset ScreenCapture uk.co.georgegillams.Contraster
```

Then rebuild, run, and grant permission again through the tutorial or System Settings.

**Use the right scheme for what you are testing.** To verify the permission onboarding flow, run the **Contraster** scheme. Use **DEBUG Contraster** when you already have permission and want to jump straight into picking.

### What Contraster accesses

The app is sandboxed. Screen capture is governed by macOS privacy (TCC): users grant **Screen Recording** in System Settings. Contraster uses that only to read the colour at the cursor position during a pick. See `Contraster/Trunk/Info.plist` for the usage description shown to users.

## License

MIT — see [LICENSE](LICENSE).

## Release

- Update version (marketing version) and build (needs incrementing). In XCode, click Contraster -> General -> Identity -> Version/Build
- Take screenshots at 1280x800
- Clean
- Create build online at https://appstoreconnect.apple.com/
- Archive
- Upload
