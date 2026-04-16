param([string]$AppPath)

# Validate the .app path exists
if (-not (Test-Path $AppPath)) {
    Write-Error "Path not found: $AppPath"
    exit 1
}

$appName = Split-Path $AppPath -Leaf
if ($appName -notlike "*.app") {
    Write-Error "Path must point to a .app folder"
    exit 1
}

# Copy .app to a simple staging path for easy folder picker navigation
$stagingDir = Join-Path $env:USERPROFILE "ipasim-apps"
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

$dest = Join-Path $stagingDir $appName
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
Copy-Item -Path $AppPath -Destination $dest -Recurse

# Kill existing ipaSim and relaunch (triggers folder picker)
Get-Process | Where-Object { $_.ProcessName -like "*IpaSim*" } | Stop-Process -Force 2>$null
Start-Sleep 1

$pkgFamily = (Get-AppxPackage | Where-Object { $_.Name -eq "0ee863f9-dcc5-4d3b-9c2a-457bcfafc07e" }).PackageFamilyName
Start-Process "shell:AppsFolder\${pkgFamily}!App"
Start-Sleep 3

$proc = Get-Process | Where-Object { $_.ProcessName -like "*IpaSim*" }
$result = @{
    status = "picker_open"
    staged_path = $dest
    instruction = "The folder picker dialog is now open. Use take_screenshot to see it, then navigate to $stagingDir and select the $appName folder. Use tap to click through the dialog."
    pid = if ($proc) { $proc.Id } else { 0 }
}
Write-Output ($result | ConvertTo-Json)
