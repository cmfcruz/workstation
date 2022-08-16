#!/usr/bin/env bash

# Install Homebrew
test -f /usr/local/bin/brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install packages using Homebrew
brew install \
    cue-lang/tap/cue \
    derailed/k9s/k9s \
    fluxcd/tap/flux \
    gh \
    git-secret \
    gnupg \
    kubectl \
    pyenv \
    shellcheck \
    terraform \
    terragrunt \
    tree \
    wget \
    yq

# Install packages using Homebrew casks
brew install --cask \
    docker \
    iterm2 \
    visual-studio-code

# Change shell to Z Shell
chsh -s /bin/zsh

# Require git commit signing
git config --global commit.gpgsign true

# Install Zsh Autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
grep 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' ~/.zshrc || echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc

# Install Powerline Fonts
git clone https://github.com/powerline/fonts.git
cd fonts && ./install.sh && cd .. && rm -rf fonts

# Install Pyenv configuration and install Python 3.8.12
export PYTHON_VERSION=3.8.12
grep 'export PYENV_ROOT="$HOME/.pyenv"' ~/.zshrc || echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
grep 'export PATH="$PYENV_ROOT/bin:$PATH"' ~/.zshrc || echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
grep 'eval "$(pyenv init -)"' ~/.zshrc || echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshrc
eval "$(pyenv init -)"
pyenv install $PYTHON_VERSION
pyenv global $PYTHON_VERSION

# Install nvm and install Node v16
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
bash $NVM_DIR/nvm.sh
nvm install v16
nvm alias default v16

# Install GPG configuration
grep 'export GPG_TTY=$(tty)' ~/.zshrc || echo 'export GPG_TTY=$(tty)' >> ~/.zshrc

echo 'Done.'
