#!/usr/bin/env bash

set -e

sudo dnf makecache
sudo dnf install -y \
  ca-certificates \
  curl \
  dnf-plugins-core

# Add known sources and update repository list
# CloudFlare
sudo dnf-3 config-manager --add-repo https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Update existing packages
sudo dnf -y update

# Install homebrew prerequisites
sudo dnf group install -y \
  development-tools
sudo dnf install -y \
  procps-ng \
  curl \
  file

# Install pyenv dependencies
sudo dnf install -y \
  make \
  gcc \
  patch \
  zlib-devel \
  bzip2 \
  bzip2-devel \
  readline-devel \
  sqlite \
  sqlite-devel \
  openssl-devel \
  tk-devel \
  libffi-devel \
  xz-devel \
  libuuid-devel \
  gdbm-libs \
  libnsl2

# Install Docker Desktop Prerequisites
sudo dnf install -y \
  dnf-plugins-core \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin \
  gnome-terminal \
  qemu-system-x86 \
  qemu-kvm

# Install packages using apt
sudo dnf install -y \
  awscli2 \
  cloudflare-warp \
  gh \
  git-secret \
  gnome-tweaks \
  jq \
  neovim \
  pam-u2f \
  pamu2fcfg \
  ripgrep \
  shellcheck \
  tmux \
  tree \
  wget \
  vim \
  xclip \
  yubikey-manager

# Install Homebrew
test -f /usr/local/bin/brew || /bin/bash -c "NONINTERACTIVE=1 $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
grep 'export PATH="/home/linuxbrew/.linuxbrew/bin/:$PATH"' ~/.bash_profile || echo 'export PATH="/home/linuxbrew/.linuxbrew/bin/:$PATH"' >>~/.bash_profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install **official** packages using Homebrew
brew install \
  act \
  derailed/k9s/k9s \
  fluxcd/tap/flux \
  helm \
  kubectl \
  kubeseal \
  saml2aws \
  yq

# Install Flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Flatpak packages
flatpak install flathub \
  com.spotify.Client

# Install nvm and install Node v20
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
grep 'export NVM_DIR="$HOME/.nvm"' ~/.bash_profile || echo 'export NVM_DIR="$HOME/.nvm"' >>~/.bash_profile
grep '"$NVM_DIR/nvm.sh"' ~/.bash_profile || echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >>~/.bash_profile
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
  echo 'export PYENV_ROOT="$HOME/.pyenv"' >>~/.bash_profile
  echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >>~/.bash_profile
  echo 'eval "$(pyenv init - bash)"' >>~/.bash_profile
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

# Install VSCode
if [ ! -f /tmp/vscode.rpm ]; then
  wget -O /tmp/vscode.rpm "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64"
  sudo dnf install -y /tmp/vscode.rpm
fi

# Install Docker Desktop
if [ ! -f /tmp/docker-desktop.rpm ]; then
  wget -O /tmp/docker-desktop.rpm "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64&_gl=1*14tz1h*_ga*MTY5NTEyNTk1MS4xNzUzMTUzODM2*_ga_XJWPQMJYHQ*czE3NTMxNTM4MzUkbzEkZzEkdDE3NTMxNTM4NDYkajQ5JGwwJGgw"
  sudo dnf install -y /tmp/docker-desktop.rpm
fi

# Configure Yubikey
mkdir -p ~/.config/Yubico
read -p "Please attach your Yubikey then press Enter to continue.  Touch your Yubikey when it starts to blink." USERWAIT
pamu2fcfg >~/.config/Yubico/u2f_keys
# OS Login (GDM) - Require Password + YubiKey
sudo sed -i '/auth\s*include\s*system-auth/a auth required pam_u2f.so' /etc/pam.d/gdm-password
# TTY (Console) - Require Password + YubiKey
sudo sed -i '/auth\s*include\s*system-auth/a auth required pam_u2f.so' /etc/pam.d/login
# Sudo - Allow Password or YubiKey
sudo sed -i '/auth\s*include\s*system-auth/iauth sufficient pam_u2f.so cue' /etc/pam.d/sudo

# Install GPG configuration
grep 'export GPG_TTY=$(tty)' ~/.bash_profile || echo 'export GPG_TTY=$(tty)' >>~/.bash_profile

# Replicate MacOS pbcopy using xclip
grep "alias pbcopy='xclip -selection clipboard'" ~/.bash_profile || echo "alias pbcopy='xclip -selection clipboard'" >>~/.bash_profile

# Some saml2aws preferences
grep "export SAML2AWS_DISABLE_KEYCHAIN=true" ~/.bash_profile || echo "export SAML2AWS_DISABLE_KEYCHAIN=true" >>~/.bash_profile
grep "export SAML2AWS_AUTO_BROWSER_DOWNLOAD=true" ~/.bash_profile || echo "export SAML2AWS_AUTO_BROWSER_DOWNLOAD=true" >>~/.bash_profile

echo 'Done.'
