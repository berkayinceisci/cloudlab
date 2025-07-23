#!/bin/bash

if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Generating SSH key for Git..."
    echo -n "Enter your email for SSH key: "
    read email
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""

    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519

    echo "===================================================="
    echo "Your SSH public key (copy this to GitHub/GitLab):"
    echo "===================================================="
    cat ~/.ssh/id_ed25519.pub
    echo "===================================================="
    echo "Add this key to your Git provider, then press Enter to continue..."
    read dummy
fi

if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""
fi

# ==> Packages

sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    build-essential \
    vim \
    htop \
    jq \
    numactl libnuma-dev \
    hwloc \
    msr-tools \
    cpufrequtils \
    tree \
    stow \
    gnuplot \
    clangd \
    python3-venv \
    libevent-dev ncurses-dev \
    libelf-dev libdw-dev libbfd-dev \
    bison \
    pkg-config \
    sysstat \
    i7z \
    cmake libncurses5-dev ninja-build meson \
    linux-tools-common linux-tools-generic linux-tools-$(uname -r)

sudo apt install --reinstall linux-firmware

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
. "$HOME/.nvm/nvm.sh"
nvm install 22

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"
echo '. "$HOME/.cargo/env"' >~/.zshenv
cargo install ripgrep eza zoxide bat fd-find just du-dust starship git-delta
cargo install --locked tlrc

wget https://go.dev/dl/go1.24.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.24.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >>~/.zshenv

export PATH=$PATH:~/go/bin
echo 'export PATH=$PATH:~/go/bin' >>~/.zshenv
go install github.com/junegunn/fzf@latest
go install github.com/jesseduffield/lazygit@latest

git clone https://github.com/tmux/tmux.git
cd tmux
git checkout 3.5a
sh autogen.sh
./configure
make && sudo make install
cd -
rm -rf tmux

git clone git@github.com:neovim/neovim.git
cd neovim
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
cd -
rm -rf neovim

git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

cd ~
mkdir repos && cd repos
git clone git@github.com:inceisciberkay/dotfiles.git
cd dotfiles
stow *
cd ~/cloudlab

rm *.tar.gz

# ==> Settings

sudo mkdir /dev/hugepages1G
sudo mount -t hugetlbfs -o pagesize=1G none /dev/hugepages1G

. "./config.sh" || exit
check_conf
