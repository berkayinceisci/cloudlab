# dotfiles
if [ ! -d "$HOME/dotfiles" ]; then
    echo "Setting up dotfiles..."
    git clone git@github.com:berkayinceisci/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    if ! stow *; then
        echo "stow failed, removing dotfiles directory..."
        cd - >/dev/null
        rm -rf ~/dotfiles
        exit 1
    fi
    cd - >/dev/null
else
    echo "dotfiles already exist, skipping..."
fi
