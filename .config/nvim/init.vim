if !empty($USERPROFILE) 
	let $HOME = $USERPROFILE
end
source ~/.vimrc
lua require('base')

au TextYankPost * silent! lua vim.highlight.on_yank()
