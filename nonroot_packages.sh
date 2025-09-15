#!/bin/bash

# ==> Packages

mkdir -p ~/.local/bin

# zsh
wget https://sourceforge.net/projects/zsh/files/zsh/5.9/zsh-5.9.tar.xz/download -O zsh-5.9.tar.xz
tar -xf zsh-5.9.tar.xz
cd zsh-5.9
./configure --prefix=$HOME/.local
make
make install
cd -
rm -rf zsh-5.9

git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting

echo '[ -f $HOME/.local/bin/zsh ] && exec $HOME/bin/zsh -l' > ~/.profile
source ~/.profile

# atuin
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
. "$HOME/.atuin/bin/env"
atuin login
atuin sync

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"
# echo '. "$HOME/.cargo/env"' > ~/.zshenv
cargo install ripgrep eza zoxide bat fd-find just du-dust starship git-delta
cargo install --locked tlrc

# go
curl -sSL https://git.io/g-install | sh -s -- -y
# todo: ensure go is visible in the current session
go install github.com/junegunn/fzf@latest
go install github.com/jesseduffield/lazygit@latest

# npm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
. "$HOME/.nvm/nvm.sh"
nvm install 22
npm install -g @anthropic-ai/claude-code

# tmux
git clone https://github.com/tmux/tmux.git
cd tmux
git checkout 3.5a
sh autogen.sh
./configure --prefix=$HOME/.local
make && make install
cd -
rm -rf tmux

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# neovim
git clone https://github.com/neovim/neovim.git
cd neovim
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=$HOME/.local
make install
cd -
rm -rf neovim

# stow
wget https://ftp.gnu.org/gnu/stow/stow-2.3.1.tar.gz
tar -xzf stow-2.3.1.tar.gz
cd stow-2.3.1
./configure --prefix=$HOME/.local
make
make install
cd -
rm -rf stow-2.3.1

# dotfiles
ssh-keyscan github.com >> ~/.ssh/known_hosts

cd ~
mkdir repos && cd repos
git clone git@github.com:berkayinceisci/dotfiles.git
cd dotfiles
stow *
cd ~/cloudlab

rm *.tar.gz

echo "Local packages are installed"
