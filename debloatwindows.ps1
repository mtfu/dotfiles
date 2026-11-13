# Win11Debloat, pinned to a release and checked against its SHA-256 before it runs.
# To update: pick a tag at https://github.com/Raphire/Win11Debloat/releases and copy the sha256 digest of its
# Win11Debloat.zip asset.
$version = '2026.10.30'
$sha256 = '6830bf501d2740c3317133ac0ecdc2a3ab80ed7f6c83e7f0f20dc66afbf758a7'

$zip = Join-Path $env:TEMP "Win11Debloat-$version.zip"
$dir = Join-Path $env:TEMP "Win11Debloat-$version"
Invoke-WebRequest "https://github.com/Raphire/Win11Debloat/releases/download/$version/Win11Debloat.zip" -OutFile $zip
if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $sha256) {
    Remove-Item $zip
    throw "Win11Debloat.zip does not match the pinned SHA-256; not running it."
}
Expand-Archive $zip $dir -Force
Remove-Item $zip

# Like upstream's launcher: run it elevated in Windows PowerShell, without PowerShell 7's module paths.
$modulePath = $env:PSModulePath
$env:PSModulePath = ($modulePath -split ';' | Where-Object { $_ -like '*WindowsPowerShell*' }) -join ';'
try {
    Start-Process powershell.exe -Verb RunAs -Wait -ArgumentList "-ExecutionPolicy Bypass -File `"$dir\Win11Debloat-$version\Win11Debloat.ps1`""
} finally {
    $env:PSModulePath = $modulePath
    Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
}
