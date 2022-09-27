param ([Parameter()] $path = "dotfiles")

choco install syncthing -y

New-Item -ItemType HardLink -Force -Path "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\syncthing.lnk" -Target "$env:USERPROFILE\$path\syncthing\syncthing.lnk";
