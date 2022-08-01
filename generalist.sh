#!/usr/bin/env bash

# Install Homebrew
test -f /usr/local/bin/brew || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install packages using Homebrew
brew install \
    awscli \
    cue-lang/tap/cue \
    derailed/k9s/k9s \
    fluxcd/tap/flux \
    gh \
    git-secret \
    gnupg \
    kubectl \
    pyenv \
    shellcheck \
    starship \
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

# Install Starship Config and set a sane default timeout value for long running background commands
grep 'eval "$(starship init zsh)"' ~/.zshrc || echo 'eval "$(starship init zsh)"' >> ~/.zshrc
if [ ! -f ~/.config/starship.toml ]
then
    mkdir -p ~/.config
    echo "command_timeout = 5000" > ~/.config/starship.toml
fi

# Install Powerline Fonts
git clone https://github.com/powerline/fonts.git --depth=1
eval "$(cd fonts && ./install.sh && rm -rf fonts)"

# Install Pyenv configuration and install Python 3.8.12
grep 'export PYENV_ROOT="$HOME/.pyenv"' ~/.zshrc || echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
grep 'export PATH="$PYENV_ROOT/bin:$PATH"' ~/.zshrc || echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
grep 'eval "$(pyenv init -)"' ~/.zshrc || echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshrc
eval "$(pyenv init -)"
pyenv install 3.8.12

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# Install GPG configuration
grep 'export GPG_TTY=$(tty)' ~/.zshrc || echo 'export GPG_TTY=$(tty)' >> ~/.zshrc

echo 'Done.'
