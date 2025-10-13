#!/bin/bash

# ==> Packages

ssh-keyscan github.com >> ~/.ssh/known_hosts
mkdir -p ~/.local
export PATH="$HOME/.local/bin:$PATH"

# stow
if ! command -v stow &> /dev/null; then
    echo "Installing stow..."
    wget https://ftp.gnu.org/gnu/stow/stow-2.3.1.tar.gz
    tar -xzf stow-2.3.1.tar.gz
    cd stow-2.3.1
    ./configure --prefix=$HOME/.local
    make
    make install
    cd -
    rm -rf stow-2.3.1
else
    echo "stow already installed, skipping..."
fi

# ncurses library
if ! command -v ncursesw6-config &> /dev/null && [ ! -f "$HOME/.local/lib/pkgconfig/ncursesw.pc" ]; then
    echo "Installing ncurses..."
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
else
    echo "ncurses already installed, skipping..."
fi

# zsh
if ! command -v zsh &> /dev/null; then
    echo "Installing zsh..."
    wget https://sourceforge.net/projects/zsh/files/zsh/5.9/zsh-5.9.tar.xz/download -O zsh-5.9.tar.xz
    tar -xf zsh-5.9.tar.xz
    cd zsh-5.9
    ./configure --prefix=$HOME/.local CPPFLAGS="-I$HOME/.local/include" LDFLAGS="-L$HOME/.local/lib" --enable-multibyte
    make
    make install
    cd -
    rm -rf zsh-5.9
    echo '[ -f $HOME/.local/bin/zsh ] && exec $HOME/.local/bin/zsh -l' > ~/.profile
else
    echo "zsh already installed, skipping..."
fi

git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions &>/dev/null
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting &>/dev/null

# rust
if ! command -v rustc &> /dev/null || ! command -v cargo &> /dev/null; then
    echo "Installing rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    . "$HOME/.cargo/env"

    cargo install --locked tlrc
else
    echo "rust already installed, skipping installation..."
fi

cargo install ripgrep eza zoxide bat fd-find just du-dust starship git-delta

# go
if ! command -v go &> /dev/null; then
    echo "Installing go..."
    rm -rf ~/.local/go
    wget https://golang.org/dl/go1.25.1.linux-amd64.tar.gz
    tar -C ~/.local -xzf go1.25.1.linux-amd64.tar.gz
    export PATH="$HOME/.local/go/bin:$PATH"
    export GOROOT="$HOME/.local/go"
    export GOPATH="$HOME/go"
    export PATH="$HOME/go/bin:$PATH"
else
    echo "go already installed, skipping installation..."
fi

go install github.com/junegunn/fzf@latest
go install github.com/jesseduffield/lazygit@latest

# npm/nvm
if ! command -v nvm &> /dev/null && [ ! -s "$HOME/.nvm/nvm.sh" ]; then
    echo "Installing nvm and node..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    . "$HOME/.nvm/nvm.sh"
    nvm install 22

    npm install -g @anthropic-ai/claude-code
else
    echo "nvm already installed, skipping..."
fi

# tmux
if ! command -v tmux &> /dev/null; then
    echo "Installing tmux..."
    git clone https://github.com/tmux/tmux.git
    cd tmux
    git checkout 3.5a
    sh autogen.sh
    ./configure --prefix=$HOME/.local
    make && make install
    cd -
    rm -rf tmux
else
    echo "tmux already installed, skipping..."
fi

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm &>/dev/null

# neovim
if ! command -v nvim &> /dev/null; then
    echo "Installing neovim..."
    git clone https://github.com/neovim/neovim.git
    cd neovim
    git checkout stable
    make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=$HOME/.local
    make install
    cd -
    rm -rf neovim
else
    echo "neovim already installed, skipping..."
fi

# dotfiles
if [ ! -d "$HOME/dotfiles" ]; then
    echo "Setting up dotfiles..."
    git clone git@github.com:berkayinceisci/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    stow *
    cd -
else
    echo "dotfiles already exist, skipping..."
fi

# atuin
if ! command -v atuin &> /dev/null; then
    echo "Installing atuin..."
    bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
    . "$HOME/.atuin/bin/env"
    atuin login
    atuin sync
else
    echo "atuin already installed, skipping..."
fi

rm -f *.tar.gz *.tar.xz

echo "Local packages are installed"
