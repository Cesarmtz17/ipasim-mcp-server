# ipaSim MCP Server

MCP (Model Context Protocol) server that lets Claude (or any MCP client) control an iOS emulator running on Windows via [ipaSim](https://github.com/ipasimulator/ipasim).

Claude can see the emulator screen, tap buttons, swipe, type text, and interact with iOS apps — all through natural language.

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
| `install_app(app_path)` | Stage a `.app` bundle and open the emulator. The app is copied to `D:\ipasim-apps\` for easy folder picker navigation. User must select the folder manually in the picker dialog. |
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
> **Claude:** *calls install_app, guides user through folder picker*
> The app is staged. Please select `D:\ipasim-apps\SampleApp.app` in the folder picker.
>
> **You:** Done, it's loaded
>
> **Claude:** *calls take_screenshot*
> I can see a calculator app. Let me try adding 2 + 3.
> *calls tap(x, y) on "2", then tap on "+", then tap on "3", then tap on "="*
> *calls take_screenshot*
> The result is 5!

## Known limitations

- **install_app** requires manual folder selection. The UWP `FolderPicker` dialog cannot be automated programmatically from external processes (Windows security restriction).
- Only runs **Objective-C** iOS apps. Swift/SwiftUI apps are not supported by ipaSim.
- ipaSim itself is a 2019 project with limited iOS API coverage. Complex apps may not work.

## License

MIT
