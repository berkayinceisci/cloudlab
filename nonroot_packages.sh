#!/bin/bash
set -euo pipefail

cd $HOME/cloudlab

export PATH="$HOME/.local/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.local/lib:${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

if ! grep -q "PKG_CONFIG_PATH" $HOME/.profile; then
	echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"' >>$HOME/.profile
	echo 'export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"' >>$HOME/.profile
fi

# ==> Packages

# ncurses library
if ! command -v ncursesw6-config &>/dev/null && [ ! -f "$HOME/.local/lib/pkgconfig/ncursesw.pc" ]; then
	echo "Installing ncurses..."
	wget https://ftp.gnu.org/gnu/ncurses/ncurses-6.4.tar.gz
	tar -xzf ncurses-6.4.tar.gz
	cd ncurses-6.4
	./configure --prefix=$HOME/.local --with-shared --enable-widec
	make
	make install
	cd -
	rm -rf ncurses-6.4
else
	echo "ncurses already installed, skipping..."
fi

# zsh
if ! command -v zsh &>/dev/null; then
	echo "Installing zsh..."
	wget https://sourceforge.net/projects/zsh/files/zsh/5.9/zsh-5.9.tar.xz/download -O zsh-5.9.tar.xz
	tar -xf zsh-5.9.tar.xz
	cd zsh-5.9
	./configure --prefix=$HOME/.local CPPFLAGS="-I$HOME/.local/include" LDFLAGS="-L$HOME/.local/lib" --enable-multibyte
	make
	make install
	cd -
	rm -rf zsh-5.9
	echo '[ -f $HOME/.local/bin/zsh ] && exec $HOME/.local/bin/zsh -l' >>$HOME/.profile
else
	echo "zsh already installed, skipping..."
fi

if [[ ! -d "$HOME/.zsh/zsh-autosuggestions" ]]; then
	git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/zsh-autosuggestions"
fi
if [[ ! -d "$HOME/.zsh/zsh-syntax-highlighting" ]]; then
	git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.zsh/zsh-syntax-highlighting"
fi

# rust
if ! command -v rustc &>/dev/null || ! command -v cargo &>/dev/null; then
	echo "Installing rust..."
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	. "$HOME/.cargo/env"
else
	echo "rust already installed, skipping installation..."
fi

cargo install ripgrep eza zoxide bat fd-find just du-dust starship git-delta stylua \
	tokei hyperfine hexyl procs bacon serie cargo-generate tree-sitter-cli dysk
cargo install --force yazi-build
cargo install resvg
cargo install --locked tlrc ripgrep_all uv
uv tool install ruff
uv tool install trash-cli
uv tool install bpytop
uv tool install speedtest-cli
uv tool install cmakelang
uv tool install docutils
uv tool install git-filter-repo

# yazi plugins
ya pkg add yazi-rs/plugins:toggle-pane || true
ya pkg add boydaihungst/restore || true

# go
if ! command -v go &>/dev/null; then
	echo "Installing go..."
	rm -rf $HOME/.local/go
	GO_VERSION=$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1)
	wget "https://golang.org/dl/${GO_VERSION}.linux-amd64.tar.gz"
	tar -C $HOME/.local -xzf "${GO_VERSION}.linux-amd64.tar.gz"
	export PATH="$HOME/.local/go/bin:$PATH"
	export GOROOT="$HOME/.local/go"
	export GOPATH="$HOME/go"
	export PATH="$HOME/go/bin:$PATH"
else
	echo "go already installed, skipping installation..."
fi

go install github.com/junegunn/fzf@latest
go install github.com/jesseduffield/lazygit@latest
go install mvdan.cc/sh/v3/cmd/shfmt@latest
go install github.com/charmbracelet/glow@latest
go install github.com/zricethezav/gitleaks/v8@latest

# python3.11
if ! command -v python3.11 &>/dev/null; then
	echo "Installing Python 3.11..."
	rm -rf Python-3.11.6 Python-3.11.6.tgz
	wget https://www.python.org/ftp/python/3.11.6/Python-3.11.6.tgz
	tar xzf Python-3.11.6.tgz
	(
		cd Python-3.11.6
		./configure --prefix="$HOME/.local" --enable-optimizations
		make -j"$(nproc)"
		make altinstall
	)
	rm -rf Python-3.11.6
else
	echo "Python 3.11 already installed, skipping installation..."
fi

# npm/nvm
if ! command -v nvm &>/dev/null && [ ! -s "$HOME/.nvm/nvm.sh" ]; then
	echo "Installing nvm and node..."
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
	. "$HOME/.nvm/nvm.sh"
	nvm install 22

	curl -fsSL https://claude.ai/install.sh | bash
	npm install -g pyright prettier prettier-plugin-solidity ccusage

	claude plugin marketplace add anthropics/claude-plugins-official
	claude plugin install feature-dev@claude-plugins-official
	claude plugin install code-review@claude-plugins-official
	claude plugin install playwright@claude-plugins-official
else
	echo "nvm already installed, skipping..."
fi

# tmux
if ! command -v tmux &>/dev/null || [[ "$(tmux -V)" < "tmux 3.3" ]]; then
	echo "Installing tmux..."
	rm -rf tmux
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

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
	git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# neovim
if ! command -v nvim &>/dev/null; then
	echo "Installing neovim..."
	rm -rf neovim
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

# atuin
if ! command -v atuin &>/dev/null; then
	echo "Installing atuin..."
	bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh) --non-interactive
else
	echo "atuin already installed, skipping..."
fi

rm -f *.tar.gz *.tar.xz *.tgz

echo "Local packages are installed"
