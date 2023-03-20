lua require('mtfu.base')
lua require('mtfu.highlights')
lua require('mtfu.maps')
lua require('mtfu.plugins')

if has("win32")
  lua require('mtfu.windows')
end
if has("wsl")
  lua require('mtfu.wsl')
end
