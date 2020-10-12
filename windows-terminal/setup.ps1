$path = "$env:userprofile\AppData\Local\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json";
Remove-Item $path;
cmd /c mklink $path "$env:userprofile\dotfiles\windows-terminal\settings.json";
## https://github.com/lextm/windowsterminal-shell
& {
    $f = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName() + '.ps1'); 
    Invoke-RestMethod https://raw.githubusercontent.com/lextm/windowsterminal-shell/master/install.ps1 > $f;
    & $f -PreRelease;
    Remove-Item $f
  }