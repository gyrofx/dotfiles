sudo apt install zsh hyper git

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
./install-fonts.sh
git clone https://github.com/gyrofx/dotfiles
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

brew install node 
brew install oven-sh/bun/bun
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

