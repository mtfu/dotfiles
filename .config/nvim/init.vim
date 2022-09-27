if !empty($USERPROFILE) 
	let $HOME = $USERPROFILE
end
source ~/.vimrc
lua require('base')
