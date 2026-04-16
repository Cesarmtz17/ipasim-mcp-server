param([string]$AppPath)

$pkgFamily = (Get-AppxPackage | Where-Object { $_.Name -eq "0ee863f9-dcc5-4d3b-9c2a-457bcfafc07e" }).PackageFamilyName
if (-not $pkgFamily) {
    Write-Error "ipaSim not installed"
    exit 1
}

Start-Process "shell:AppsFolder\${pkgFamily}!App"
Start-Sleep 2

$proc = Get-Process | Where-Object { $_.ProcessName -like "*IpaSim*" }
if ($proc) {
    Write-Output @{ pid = $proc.Id; status = "running" } | ConvertTo-Json
} else {
    Write-Error "ipaSim failed to start"
    exit 1
}
