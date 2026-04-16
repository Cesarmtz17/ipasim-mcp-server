# ipaSim MCP Server

> **⚠️ This is a proof-of-concept / educational project. It does NOT run real iOS apps.**

MCP server that lets Claude control [ipaSim](https://github.com/ipasimulator/ipasim), a 2019 research project that emulates a very limited subset of iOS on Windows.

## What ipaSim actually is

ipaSim was a **university thesis project** by Jan Joneš (2019). It is NOT a real iOS emulator. Here's what it does and doesn't do:

### ❌ What it CANNOT do
- **Cannot run your app** — no React Native, Expo, Flutter, Swift, SwiftUI, or any modern iOS app
- **Cannot run .ipa files** — not from Xcode, not from the App Store, not from EAS Build
- **Cannot replace Xcode Simulator** — it's not even close
- **No Swift support** — only Objective-C
- **No App Store apps** — none at all
- **Limited iOS APIs** — CoreData, AVFoundation, CoreLocation, etc. are mostly stubs

### ✅ What it CAN do
- Run **4 sample Objective-C apps** that were specifically compiled for it in 2019:
  - HelloWorld (shows text)
  - SampleApp (basic calculator)
  - SampleGame (simple game)
  - IpasimBenchmark
- Demonstrate how MCP tools can control a desktop application via Win32 automation
- Serve as a learning exercise for building MCP servers

### If you need to test real apps, use these instead:

| Solution | iOS | Android | Cost | Link |
|----------|-----|---------|------|------|
| **Android Emulator MCP** | ❌ | ✅ Any APK | Free | [android-emulator-mcp](https://github.com/Cesarmtz17/android-emulator-mcp) |
| **BrowserStack MCP** | ✅ Real iPhones | ✅ Real Androids | Paid (100 min free trial) | [browserstack-device-mcp](https://github.com/Cesarmtz17/browserstack-device-mcp) |
| **Xcode Simulator** | ✅ Full support | ❌ | Free (macOS only) | Built into Xcode |

## What it's good for

- Demonstrating MCP server capabilities with a visual emulator
- Learning how to build MCP tools that interact with desktop applications
- Experimenting with Win32 automation from Node.js
- Running the included ipaSim sample apps for fun

## Requirements

- **Windows 10/11** (x64)
- **Node.js** 18+
- **ipaSim** installed as a UWP app ([releases](https://github.com/ipasimulator/ipasim/releases))
  - Download `ipasim-build-v1.0.1-*.zip` from the latest release
  - Run `Add-AppDevPackage.ps1` as administrator to install
- **iOS .app bundles** to run (sample apps included in `ipasim-samples-v1.0.zip` from releases)

## Installation

```bash
git clone https://github.com/Cesarmtz17/ipasim-mcp-server.git
cd ipasim-mcp-server
npm install
```

## Setup

Add to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "mcpServers": {
    "ipasim": {
      "command": "node",
      "args": ["/absolute/path/to/ipasim-mcp-server/index.js"]
    }
  }
}
```

Or for Claude Desktop (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "ipasim": {
      "command": "node",
      "args": ["C:\\path\\to\\ipasim-mcp-server\\index.js"]
    }
  }
}
```

## Tools

| Tool | Description |
|------|-------------|
| `open_emulator` | Launch the ipaSim iOS emulator |
| `install_app(app_path)` | Stage a `.app` bundle and open the emulator. The app is copied to `%USERPROFILE%\ipasim-apps` for easy navigation. User must select the folder manually in the picker dialog. |
| `take_screenshot` | Capture the emulator window as a PNG image (returned as base64) |
| `tap(x, y)` | Tap at coordinates relative to the emulator window |
| `swipe(x1, y1, x2, y2)` | Swipe gesture from point to point |
| `type_text(text)` | Type text into the currently focused field |
| `press_button(button)` | Press a hardware button: `home`, `lock`, `volume_up`, `volume_down` |

## How it works

```
Claude <-> MCP Server (Node.js) <-> PowerShell scripts <-> Win32 API <-> ipaSim UWP app
```

- **Screenshots**: Win32 `PrintWindow` API captures the UWP window
- **Input**: Win32 `mouse_event` / `keybd_event` sends clicks and keystrokes
- **Launch**: UWP app activation via `shell:AppsFolder`

## Example conversation

> **You:** Open the iOS emulator and show me what's on screen
>
> **Claude:** *calls open_emulator, then take_screenshot*
> I can see the ipaSim emulator showing "Loading...". It needs an app to run.
>
> **You:** Load the SampleApp calculator
>
> **Claude:** *calls install_app, then tells user to select folder*
> The app is staged. Please select the SampleApp.app folder in the picker.
>
> **You:** Done, it's loaded
>
> **Claude:** *calls take_screenshot*
> I can see a calculator app. Let me try adding 2 + 3.
> *calls tap on "2", "+", "3", "="*
> The result is 5!

## Known limitations

- **install_app** requires manual folder selection. The UWP `FolderPicker` dialog cannot be automated from external processes (Windows security restriction).
- Only Objective-C apps work. No Swift, SwiftUI, React Native, Expo, or Flutter.
- ipaSim has limited iOS API coverage — complex apps will crash.

## License

MIT
