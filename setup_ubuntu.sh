#!/usr/bin/env bash

set -eo pipefail

sudo apt update
sudo apt install -y \
  ca-certificates \
  curl

# Add known sources and update repository list
# CloudFlare
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg |
  sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [arch=amd64 \
  signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] \
  https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" |
  sudo tee /etc/apt/sources.list.d/cloudflare-client.list

# Spotify
curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc \
  | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb https://repository.spotify.com stable non-free" \
  | sudo tee /etc/apt/sources.list.d/spotify.list

# Docker
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt update

# Install packages
sudo apt install -y \
  augeas-lenses \
  bind9-dnsutils \
  build-essential \
  clamav \
  clamav-daemon \
  cloudflare-warp \
  containerd.io \
  curl \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin \
  file \
  git \
  gnupg \
  jq \
  libbz2-dev \
  libffi-dev \
  liblzma-dev \
  libncursesw5-dev \
  libpam-pwquality \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  libxml2-dev \
  libxmlsec1-dev \
  net-tools \
  procps \
  scdaemon \
  shellcheck \
  software-properties-common \
  spotify-client \
  tk-dev \
  tmux \
  tree \
  ufw \
  unzip \
  vim \
  wget \
  xclip \
  xz-utils \
  zlib1g-dev

# Enable firewall
sudo ufw enable

# Enforce password quality policy in PAM
sudo sed -i 's/^\(password\s\+requisite\s\+pam_pwquality.so\b.*\)$/password requisite pam_pwquality.so retry=3 minlen=8 minclass=3/' \
  /etc/pam.d/common-password

# Configure ClamAV for daily updates and scans
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl enable --now clamav-freshclam

# Weekly scan via systemd timer using clamdscan (uses running daemon, faster than clamscan)
sudo tee /etc/systemd/system/clamdscan.service >/dev/null <<'EOF'
[Unit]
Description=Weekly ClamAV scan
After=clamav-daemon.service

[Service]
Type=oneshot
ExecStart=/usr/bin/clamdscan --recursive --infected --log=/var/log/clamav/weekly-scan.log /home
EOF

sudo tee /etc/systemd/system/clamdscan.timer >/dev/null <<'EOF'
[Unit]
Description=Weekly ClamAV scan timer

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now clamdscan.timer

# Install AWS CLI v2
if ! command -v aws &>/dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip /tmp/awscliv2.zip -d /tmp/awscliv2
  sudo /tmp/awscliv2/aws/install
  rm -rf /tmp/awscliv2.zip /tmp/awscliv2
fi

# Install Homebrew
command -v brew &>/dev/null || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
grep 'export PATH="/home/linuxbrew/.linuxbrew/bin/:$PATH"' ~/.bashrc || echo 'export PATH="/home/linuxbrew/.linuxbrew/bin/:$PATH"' >>~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install packages using Homebrew
brew tap versent/homebrew-taps
brew install \
  act \
  derailed/k9s/k9s \
  fluxcd/tap/flux \
  gh \
  git-secret \
  kubernetes-cli \
  kubeseal \
  neovim \
  ripgrep \
  saml2aws \
  yq

# Install Helm
if ! command -v helm &>/dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Install nvm and install Node v20
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  grep 'export NVM_DIR="$HOME/.nvm"' ~/.bashrc || echo 'export NVM_DIR="$HOME/.nvm"' >>~/.bashrc
  grep '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' ~/.bashrc || echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >>~/.bashrc
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install v20
nvm alias default v20

# Install balena-cli via npm
npm install -g balena-cli

# Install Pyenv and install Python 3.8
export PYTHON_VERSION=3.12
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if [ ! -d "${PYENV_ROOT}" ]; then
  curl https://pyenv.run | bash
  echo 'export PYENV_ROOT="$HOME/.pyenv"' >>~/.bashrc
  echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >>~/.bashrc
  echo 'eval "$(pyenv init - bash)"' >>~/.bashrc
  pyenv install $PYTHON_VERSION
fi
pyenv global $PYTHON_VERSION

# Install pre-commit
pip3 install pre-commit

# Install nerdfonts
NERD_FONTS_DIR=/tmp/nerd-fonts
if [ ! -d "${NERD_FONTS_DIR}" ]; then
  git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git "${NERD_FONTS_DIR}"
  pushd "${NERD_FONTS_DIR}"
  bash install.sh
  popd
  rm -rf "${NERD_FONTS_DIR}"
fi

# Install lazyvim
if [ ! -d ~/.config/nvim ]; then
  git clone https://github.com/LazyVim/starter ~/.config/nvim
fi

# Require git commit signing
git config --global commit.gpgsign true

# Install Powerline Fonts
if [ ! -d /tmp/powerline-fonts ]; then
  git clone https://github.com/powerline/fonts.git /tmp/powerline-fonts
  pushd /tmp/powerline-fonts
  bash install.sh
  popd
  rm -rf /tmp/powerline-fonts
fi

# Install GPG configuration
grep 'export GPG_TTY=$(tty)' ~/.bashrc || echo 'export GPG_TTY=$(tty)' >>~/.bashrc

# Replicate MacOS pbcopy using xclip
grep "alias pbcopy='xclip -selection clipboard'" ~/.bashrc || echo "alias pbcopy='xclip -selection clipboard'" >>~/.bashrc

# Do some environment-specific installations
[[ "$XDG_CURRENT_DESKTOP" =~ "GNOME" ]] && sudo apt install -y gnome-tweaks

# Install Brave Browser
if ! command -v brave-browser &>/dev/null; then
  curl -fsS https://dl.brave.com/install.sh | sh
fi

# Download and install Google Chrome
if ! command -v google-chrome &>/dev/null; then
  wget -O /tmp/chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
  sudo apt install -y /tmp/chrome.deb
  rm -f /tmp/chrome.deb
fi

# Install VSCode
if ! command -v code &>/dev/null; then
  wget -O /tmp/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
  sudo apt install -y /tmp/vscode.deb
  rm -f /tmp/vscode.deb
fi

# Install Docker Desktop
if ! dpkg -l docker-desktop &>/dev/null; then
  wget -O /tmp/docker-desktop-amd64.deb "https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb"
  sudo apt install -y /tmp/docker-desktop-amd64.deb
  rm -f /tmp/docker-desktop-amd64.deb
fi

echo 'Done.'
