# Git
create a ./gitconfig-local to store user settings

# WSL:
Installing

$ sudo apt-get install stow
$ sudo apt-get install zsh
$ sudo apt-get install micro


## Homebew
https://brew.sh/  
https://formulae.brew.sh/formula/dstask  

brew install thefuck

## Dstask

Download latest release   
cd /usr/local/bin/  
sudo cp /mnt/c/Users/mtfu/Downloads/dstask-linux-amd64 dstask  
sudo chmod +x dstask  

## Git
cd ~  
ls -s dotfiles/.gitconfig 

## exa, use this approach until 20.10 version of ubuntu
<!--- // https://askubuntu.com/questions/1290500/unable-to-locate-package-for-exa-on-wsl-2-ubuntu  -->
wget http://archive.ubuntu.com/ubuntu/pool/universe/r/rust-exa/exa_0.9.0-4_amd64.deb  
sudo apt-get install ./exa_0.9.0-4_amd64.deb  

## Stow (Alternative to mklinks)

### Init
$ cd ~/dotfiles  
$ stow zsh  
$ stow .gitconfig  

### Updating Configurations 
You can pull down updates to configurations with Git. When a configuration in the dotfiles has changed, you need to manually re-stow it:

$ cd ~/dotfiles  
$ git pull  
$ stow -R zsh

### Adding New Configurations
$ cd ~/dotfiles  
$ mkdir new-zsh-configuration

### Move the dotfiles from you home directory into the new configuration:
$ mv ~/.zsh* dotfiles/new-zsh-configuration  
You can also move folders or parts of folders. For example, if you have a script that you want to be available in ~/bin, just mimic the directory structure exactly in the configuration folder:  

$ cd ~/dotfiles/my-custom-script  
$ mkdir bin  
$ mv ~/bin/my-script bin
