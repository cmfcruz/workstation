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

# Install pyenv dependencies
sudo apt update \
&& sudo apt install -y \
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

# Install packages using apt
sudo apt install -y \
    docker \
    docker.io \
    docker-compose \
    jq \
    shellcheck \
    tree \
    wget \
    vim \
    zsh

# Install Pyenv configuration and install Python 3.8.12
curl https://pyenv.run | bash
grep 'export PYENV_ROOT="$HOME/.pyenv"' ~/.zshrc || echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
grep 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' ~/.zshrc || echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
grep 'eval "$(pyenv init -)"' ~/.zshrc || echo 'eval "$(pyenv init -)"' >> ~/.zshrc
export PYTHON_VERSION=3.8
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv install $PYTHON_VERSION
pyenv global $PYTHON_VERSION

# Install nvm and install Node v16
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
grep 'export NVM_DIR="$HOME/.nvm"' ~/.zshrc || echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
grep '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' ~/.zshrc || echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install v16
nvm alias default v16

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
    terraform \
    terragrunt \
    yq

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

# Install GPG configuration
grep 'export GPG_TTY=$(tty)' ~/.zshrc || echo 'export GPG_TTY=$(tty)' >> ~/.zshrc

# Show current working directory in prompt
grep 'export PS1="%m %~%# "' ~/.zshrc || echo 'export PS1="%m %~%# "' >> ~/.zshrc

echo 'Done.'
