#!/usr/bin/env bash

# Make sure .zshrc exists
touch /home/cmfcruz/.zshrc

# Install homebrew prerequisites
sudo apt-get install -y \
    build-essential \
    procps \
    curl \
    file \
    git \
    ca-certificates \
    curl \
    gnupg \
    libssl-dev \
    software-properties-common

# Install Homebrew
test -f /usr/local/bin/brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
grep 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' /home/cmfcruz/.zshrc \
    || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/cmfcruz/.zshrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"


# Install packages using Homebrew
brew install \
    balena-cli \
    derailed/k9s/k9s \
    fluxcd/tap/flux \
    gh \
    git-secret \
    kubernetes-cli \
    neovim \
    nvm \
    pyenv \
    terraform \
    terragrunt \
    yq

# Install packages using apt
sudo apt update \
&& sudo apt install -y \
    docker \
    docker.io \
    docker-compose \
    jq \
    shellcheck \
    tree \
    wget \
    vim \
    zsh

# Install pyenv dependencies
sudo apt install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    curl \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev

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
export PYTHON_VERSION=3.8
grep 'export PYENV_ROOT="$HOME/.pyenv"' ~/.zshrc || echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
grep 'export PATH="$PYENV_ROOT/bin:$PATH"' ~/.zshrc || echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
grep 'eval "$(pyenv init -)"' ~/.zshrc || echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshrc
eval "$(pyenv init -)"
pyenv install $PYTHON_VERSION
pyenv global $PYTHON_VERSION

# Install nvm and install Node v16
grep 'export NVM_DIR="$HOME/.nvm"' ~/.zshrc || echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
grep '[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"' ~/.zshrc \
    || echo '[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"' >> ~/.zshrc
nvm install v16
nvm alias default v16

# Install GPG configuration
grep 'export GPG_TTY=$(tty)' ~/.zshrc || echo 'export GPG_TTY=$(tty)' >> ~/.zshrc

# Show current working directory in prompt
grep 'export PS1="%m %~%# "' ~/.zshrc || echo 'export PS1="%m %~%# "' >> ~/.zshrc

echo 'Done.'
