# ipaSim MCP Server

MCP (Model Context Protocol) server that lets Claude (or any MCP client) control an iOS emulator running on Windows via [ipaSim](https://github.com/ipasimulator/ipasim).

Claude can see the emulator screen, tap buttons, swipe, type text, and interact with iOS apps — all through natural language.

## Important limitations

**This is a proof-of-concept, not a production iOS testing tool.**

- **Only runs legacy Objective-C apps** compiled specifically for ipaSim/WinObjC. It includes 4 sample apps (HelloWorld, SampleApp calculator, SampleGame, IpasimBenchmark).
- **Cannot run modern iOS apps**: React Native, Expo, Flutter, Swift, SwiftUI apps will NOT work. These need Apple's real iOS runtime.
- **Cannot run .ipa files** from the App Store or Xcode builds.
- **ipaSim is a 2019 research project** (thesis by Jan Joneš) with limited API coverage. It was never intended as a full iOS simulator replacement.
- **Windows only** (requires Win32 APIs for window automation).

If you need to test real iOS apps, use:
- **Xcode Simulator** (macOS only)
- **BrowserStack / Sauce Labs** (cloud-based real devices)
- **Expo Go** (for React Native/Expo development)

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
