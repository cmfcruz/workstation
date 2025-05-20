#!/usr/bin/env bash

set -e

sudo apt update
sudo apt install ca-certificates curl

# Add known sources and update repository list
# CloudFlare
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
# Docker Desktop
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
# Spotify
curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt update

# Install homebrew prerequisites
sudo apt install -y \
  build-essential \
  procps \
  file \
  git \
  curl \
  gnupg \
  libssl-dev \
  software-properties-common

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

# Install Docker Desktop Prerequisites
sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Install packages using apt
sudo apt install -y \
  cloudflare-warp \
  gnome-tweaks \
  jq \
  shellcheck \
  spotify-client \
  tmux \
  tree \
  wget \
  vim \
  xclip

# Install Homebrew
test -f /usr/local/bin/brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
grep 'export PATH="/home/linuxbrew/.linuxbrew/bin/:$PATH"' ~/.bashrc || echo 'export PATH="/home/linuxbrew/.linuxbrew/bin/:$PATH"' >>~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install packages using Homebrew
brew install \
  act \
  awscli \
  balena-cli \
  derailed/k9s/k9s \
  fluxcd/tap/flux \
  gh \
  git-secret \
  helm \
  kubernetes-cli \
  kubeseal \
  neovim \
  ripgrep \
  saml2aws \
  yq

# Install nvm and install Node v20
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
grep 'export NVM_DIR="$HOME/.nvm"' ~/.bashrc || echo 'export NVM_DIR="$HOME/.nvm"' >>~/.bashrc
grep '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' ~/.bashrc || echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >>~/.bashrc
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install v20
nvm alias default v20

# Install Pyenv and install Python 3.8.12
export PYTHON_VERSION=3.8
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if [ ! -d "${PYENV_ROOT}" ]; then
  curl https://pyenv.run | bash
  echo 'export PYENV_ROOT="$HOME/.pyenv"' >>~/.bashrc
  echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >>~/.bashrc
  echo 'eval "$(pyenv init - bash)"' >>~/.bashrc
  pyenv install $PYTHON_VERSION
fi

# Install nerdfonts
NERD_FONTS_DIR=/tmp/nerd-fonts
if [ ! -d "${NERD_FONTS_DIR}" ]; then
  git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git "${NERD_FONTS_DIR}"
  pushd "${NERD_FONTS_DIR}"
  bash install.sh
  popd
fi

# Install lazyvim
if [ ! -d ~/.config/nvim ]; then
  git clone https://github.com/LazyVim/starter ~/.config/nvim
fi

# Require git commit signing
git config --global commit.gpgsign true

# Install Powerline Fonts
git clone https://github.com/powerline/fonts.git
cd fonts && ./install.sh && cd .. && rm -rf fonts

# Install GPG configuration
grep 'export GPG_TTY=$(tty)' ~/.bashrc || echo 'export GPG_TTY=$(tty)' >>~/.bashrc

# Replicate MacOS pbcopy using xclip
grep "alias pbcopy='xclip -selection clipboard'" ~/.bashrc || echo "alias pbcopy='xclip -selection clipboard'" >>~/.bashrc

# Do some environment-specific installations
[[ "$XDG_CURRENT_DESKTOP" =~ "GNOME" ]] && sudo apt install -y gnome-tweaks

# Download and install Google Chrome
if [ ! -f /tmp/chrome.deb ]; then
  wget -O /tmp/chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
  sudo apt install -y /tmp/chrome.deb
fi

# Install VSCode
if [ ! -f /tmp/vscode.deb ]; then
  wget -O /tmp/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
  sudo apt install -y /tmp/vscode.deb
fi

# Install Docker Desktop
if [ ! -f /tmp/docker-desktop.deb ]; then
  wget -O /tmp/docker-desktop.deb "https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64&_gl=1*jce70q*_ga*MTA3MTU4MDYyLjE3MzU3OTIyMzg.*_ga_XJWPQMJYHQ*MTczNTc5MjIzOC4xLjEuMTczNTc5MjQ4MC42MC4wLjA."
  sudo apt install -y /tmp/docker-desktop.deb
fi

echo 'Done.'
