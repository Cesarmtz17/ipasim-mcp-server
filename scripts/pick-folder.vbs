Set WshShell = WScript.CreateObject("WScript.Shell")
appPath = WScript.Arguments(0)

' Wait and activate the folder picker
WScript.Sleep 1000
result = WshShell.AppActivate("Seleccionar carpeta")
If Not result Then
    WScript.Echo "ERROR: Could not activate folder picker"
    WScript.Quit 1
End If
WScript.Sleep 500

' Alt+D to focus address bar
WshShell.SendKeys "%d"
WScript.Sleep 500

' Type the path directly (SendKeys types it)
' Escape special SendKeys characters
safePath = Replace(appPath, "+", "{+}")
safePath = Replace(safePath, "^", "{^}")
safePath = Replace(safePath, "%", "{%}")
safePath = Replace(safePath, "~", "{~}")
safePath = Replace(safePath, "(", "{(}")
safePath = Replace(safePath, ")", "{)}")
WshShell.SendKeys safePath
WScript.Sleep 500

' Enter to navigate
WshShell.SendKeys "{ENTER}"
WScript.Sleep 2000

' Select Folder button - try Tab then Enter
WshShell.SendKeys "{TAB}"
WScript.Sleep 200
WshShell.SendKeys "{ENTER}"
WScript.Sleep 1000

WScript.Echo "OK"
