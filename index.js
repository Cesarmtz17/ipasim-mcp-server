import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { readFile, mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

const execFileAsync = promisify(execFile);
const SCRIPTS_DIR = join(import.meta.dirname, "scripts");

function runPS(script, args = []) {
  const psArgs = [
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", join(SCRIPTS_DIR, script),
    ...args,
  ];
  return execFileAsync("powershell.exe", psArgs, { timeout: 30000 });
}

const server = new McpServer({
  name: "ipasim-emulator",
  version: "1.0.0",
});

server.tool(
  "open_emulator",
  "Launch the ipaSim iOS emulator",
  {},
  async () => {
    const { stdout } = await runPS("launch.ps1");
    return { content: [{ type: "text", text: stdout.trim() }] };
  }
);

server.tool(
  "install_app",
  "Stage an iOS .app bundle and launch the emulator with its folder picker open. The app is copied to D:\\ipasim-apps for easy navigation. After calling this, use take_screenshot + tap to navigate the folder picker to D:\\ipasim-apps and select the .app folder.",
  { app_path: z.string().describe("Absolute path to the .app folder") },
  async ({ app_path }) => {
    const { stdout } = await runPS("install-app.ps1", ["-AppPath", app_path]);
    return { content: [{ type: "text", text: stdout.trim() }] };
  }
);

server.tool(
  "take_screenshot",
  "Capture a screenshot of the ipaSim emulator window. Returns the image as base64 PNG.",
  {},
  async () => {
    const tmp = await mkdtemp(join(tmpdir(), "ipasim-"));
    const imgPath = join(tmp, "screenshot.png");
    await runPS("screenshot.ps1", ["-OutputPath", imgPath]);
    const data = await readFile(imgPath);
    return {
      content: [{
        type: "image",
        data: data.toString("base64"),
        mimeType: "image/png",
      }],
    };
  }
);

server.tool(
  "tap",
  "Tap at coordinates (x, y) relative to the emulator window",
  {
    x: z.number().describe("X coordinate relative to emulator window"),
    y: z.number().describe("Y coordinate relative to emulator window"),
  },
  async ({ x, y }) => {
    const { stdout } = await runPS("input.ps1", ["-Action", "tap", "-X", String(x), "-Y", String(y)]);
    return { content: [{ type: "text", text: stdout.trim() }] };
  }
);

server.tool(
  "swipe",
  "Swipe from (x1,y1) to (x2,y2) on the emulator window",
  {
    x1: z.number(), y1: z.number(),
    x2: z.number(), y2: z.number(),
  },
  async ({ x1, y1, x2, y2 }) => {
    const { stdout } = await runPS("input.ps1", [
      "-Action", "swipe",
      "-X", String(x1), "-Y", String(y1),
      "-X2", String(x2), "-Y2", String(y2),
    ]);
    return { content: [{ type: "text", text: stdout.trim() }] };
  }
);

server.tool(
  "type_text",
  "Type text into the currently focused field in the emulator",
  { text: z.string().describe("Text to type") },
  async ({ text }) => {
    const { stdout } = await runPS("input.ps1", ["-Action", "type", "-Text", text]);
    return { content: [{ type: "text", text: stdout.trim() }] };
  }
);

server.tool(
  "press_button",
  "Press a hardware button on the emulated device",
  { button: z.enum(["home", "lock", "volume_up", "volume_down"]) },
  async ({ button }) => {
    const { stdout } = await runPS("input.ps1", ["-Action", "button", "-Button", button]);
    return { content: [{ type: "text", text: stdout.trim() }] };
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
