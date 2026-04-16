param(
    [string]$Action,
    [int]$X = 0,
    [int]$Y = 0,
    [int]$X2 = 0,
    [int]$Y2 = 0,
    [string]$Text = "",
    [string]$Button = ""
)

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class InputInjector {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern void SetCursorPos(int x, int y);

    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, IntPtr dwExtraInfo);

    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);

    [DllImport("user32.dll")]
    public static extern short VkKeyScan(char ch);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left, Top, Right, Bottom;
    }

    public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    public const uint MOUSEEVENTF_LEFTUP = 0x0004;
    public const uint MOUSEEVENTF_MOVE = 0x0001;
    public const uint MOUSEEVENTF_ABSOLUTE = 0x8000;
    public const uint KEYEVENTF_KEYUP = 0x0002;
    public const byte VK_SHIFT = 0x10;

    public static IntPtr FindIpaSimWindow() {
        return FindWindow("ApplicationFrameWindow", "ipaSim");
    }

    public static void Tap(IntPtr hwnd, int relX, int relY) {
        RECT rect;
        GetWindowRect(hwnd, out rect);
        int absX = rect.Left + relX;
        int absY = rect.Top + relY;
        SetForegroundWindow(hwnd);
        Thread.Sleep(100);
        SetCursorPos(absX, absY);
        Thread.Sleep(50);
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);
        Thread.Sleep(50);
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
    }

    public static void Swipe(IntPtr hwnd, int x1, int y1, int x2, int y2) {
        RECT rect;
        GetWindowRect(hwnd, out rect);
        SetForegroundWindow(hwnd);
        Thread.Sleep(100);

        int absX1 = rect.Left + x1;
        int absY1 = rect.Top + y1;
        SetCursorPos(absX1, absY1);
        Thread.Sleep(50);
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);

        int steps = 20;
        for (int i = 1; i <= steps; i++) {
            int cx = absX1 + (rect.Left + x2 - absX1) * i / steps;
            int cy = absY1 + (rect.Top + y2 - absY1) * i / steps;
            SetCursorPos(cx, cy);
            Thread.Sleep(15);
        }
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
    }

    public static void TypeText(string text) {
        foreach (char c in text) {
            short vk = VkKeyScan(c);
            byte key = (byte)(vk & 0xFF);
            bool shift = (vk & 0x100) != 0;
            if (shift) keybd_event(VK_SHIFT, 0, 0, IntPtr.Zero);
            keybd_event(key, 0, 0, IntPtr.Zero);
            keybd_event(key, 0, KEYEVENTF_KEYUP, IntPtr.Zero);
            if (shift) keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, IntPtr.Zero);
            Thread.Sleep(30);
        }
    }
}
"@

$hwnd = [InputInjector]::FindIpaSimWindow()
if ($hwnd -eq [IntPtr]::Zero) {
    Write-Error "ipaSim window not found"
    exit 1
}

switch ($Action) {
    "tap" {
        [InputInjector]::Tap($hwnd, $X, $Y)
        Write-Output @{ action = "tap"; x = $X; y = $Y } | ConvertTo-Json
    }
    "swipe" {
        [InputInjector]::Swipe($hwnd, $X, $Y, $X2, $Y2)
        Write-Output @{ action = "swipe"; x1 = $X; y1 = $Y; x2 = $X2; y2 = $Y2 } | ConvertTo-Json
    }
    "type" {
        [InputInjector]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 200
        [InputInjector]::TypeText($Text)
        Write-Output @{ action = "type"; text = $Text } | ConvertTo-Json
    }
    "button" {
        $keyMap = @{
            "home" = 0x5B       # Win key
            "lock" = 0x91       # Scroll Lock as proxy
            "volume_up" = 0xAF
            "volume_down" = 0xAE
        }
        $vk = $keyMap[$Button]
        if ($vk) {
            [InputInjector]::SetForegroundWindow($hwnd)
            Start-Sleep -Milliseconds 100
            [InputInjector]::keybd_event([byte]$vk, 0, 0, [IntPtr]::Zero)
            [InputInjector]::keybd_event([byte]$vk, 0, 2, [IntPtr]::Zero)
            Write-Output @{ action = "button"; button = $Button } | ConvertTo-Json
        } else {
            Write-Error "Unknown button: $Button"
            exit 1
        }
    }
}
