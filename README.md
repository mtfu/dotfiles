#WSL:

Installing

$ sudo apt-get install stow
$ sudo apt-get install zsh
$ sudo apt-get install micro
$ sudo apt-get install dstask
## git clone --recursive https://github.com/mtfu/dotfiles.git
$ cd dotfiles


## Stow (Alternative to mklinks)
Updating Configurations
You can pull down updates to configurations with Git. When a configuration in the dotfiles has changed, you need to manually re-stow it:

$ cd ~/dotfiles
$ git pull
$ stow -R zsh
Adding New Configurations
New configurations are easy to add. Make a new folder in dotfiles:

$ cd ~/dotfiles
$ mkdir new-zsh-configuration
Move the dotfiles from you home directory into the new configuration:

$ mv ~/.zsh* dotfiles/new-zsh-configuration
You can also move folders or parts of folders. For example, if you have a script that you want to be available in ~/bin, just mimic the directory structure exactly in the configuration folder:

$ cd ~/dotfiles/my-custom-script
$ mkdir bin
$ mv ~/bin/my-script bin
Make sure to commit and push any new configurations:

$ cd ~/dotfiles
$ git add my-new-configuration/
$ git commit -m 'Added my-new-configuration'
$ git push origin master