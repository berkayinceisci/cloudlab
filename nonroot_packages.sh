#!/bin/bash

# ==> Packages

mkdir -p ~/.local
export PATH="$HOME/.local/bin:$PATH"

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

# ncurses library
wget https://ftp.gnu.org/gnu/ncurses/ncurses-6.4.tar.gz
tar -xzf ncurses-6.4.tar.gz
cd ncurses-6.4
./configure --prefix=$HOME/.local --with-shared --enable-widec
make
make install
cd -
rm -rf ncurses-6.4

echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"' >> ~/.profile
echo 'export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.profile

# zsh
wget https://sourceforge.net/projects/zsh/files/zsh/5.9/zsh-5.9.tar.xz/download -O zsh-5.9.tar.xz
tar -xf zsh-5.9.tar.xz
cd zsh-5.9
./configure --prefix=$HOME/.local CPPFLAGS="-I$HOME/.local/include" LDFLAGS="-L$HOME/.local/lib" --enable-multibyte
make
make install
cd -
rm -rf zsh-5.9

git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting

echo '[ -f $HOME/.local/bin/zsh ] && exec $HOME/.local/bin/zsh -l' > ~/.profile

# atuin
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
. "$HOME/.atuin/bin/env"
atuin login
atuin sync

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"
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

rm *.tar.gz
rm *.tar.xz

echo "Local packages are installed"
