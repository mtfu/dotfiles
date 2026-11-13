choco install syncthing -y

# Generated here rather than committed: a .lnk file embeds the machine name, user and account SID.
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\syncthing.lnk")
$shortcut.TargetPath = "$env:ProgramData\chocolatey\bin\syncthing.exe"
$shortcut.Arguments = '--no-console --no-browser'
$shortcut.WorkingDirectory = "$env:ProgramData\chocolatey\bin"
$shortcut.Save()
