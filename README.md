# dotfiles

## Requirements

- zsh
- brew
- git

## Install

```
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
git clone --bare https://github.com/gyrofx/dotfiles $HOME/.dotfiles

dotfiles config --local status.showUntrackedFiles no
dotfiles checkout
```

## Using the dotfiles repo

```
dotfiles add ...
dotfiles diff --staged
dotfiles commit -m "..."
```

## Install other tools

```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

```
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime\nsh 
~/.vim_runtime/install_awesome_vimrc.sh

brew install asdf node yarn fzf nnn delta starship
```

To mitigate `Can't locate JSON.pm in @INC (you may need to install the JSON module) (@INC contains: .` when autocomplete yarn commands:
```
sudo dnf install 'perl(JSON)' 'perl(JSON::PP)'
```

### Need FOnt

[Download](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip) and install FiraCode NerdFont

Unzip the downloaded and move or copy the directory to ~/.local/share/fonts directory.
Run `fc-cache -fv` to refresh the font cache.

VS Code
```
"editor.fontFamily": "FiraCode Nerd Font",
"editor.fontLigatures": true,
```
