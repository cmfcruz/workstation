#!/usr/bin/env bash

set -eou pipefail

cleanup_paths=()
cleanup() {
  if [ "${#cleanup_paths[@]}" -gt 0 ]; then
    rm -rf "${cleanup_paths[@]}"
  fi
}
trap cleanup EXIT

sudo apt-get update
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gpg \
  lsb-release

sudo install -d -m 0755 /usr/share/keyrings /etc/apt/keyrings /etc/apt/sources.list.d /etc/apt/preferences.d

apt_repo_tmp_dir="$(mktemp -d)"
cleanup_paths+=("$apt_repo_tmp_dir")

download_apt_file() {
  local url="$1"
  local output="$2"
  local tmp_file
  tmp_file="$apt_repo_tmp_dir/$(basename "$output")"

  curl --proto '=https' --tlsv1.2 -fsSL "$url" -o "$tmp_file"
  sudo install -m 0644 "$tmp_file" "$output"
}

download_apt_keyring() {
  local url="$1"
  local output="$2"
  local key_tmp
  local keyring_tmp
  key_tmp="$apt_repo_tmp_dir/$(basename "$output").key"
  keyring_tmp="$apt_repo_tmp_dir/$(basename "$output")"

  curl --proto '=https' --tlsv1.2 -fsSL "$url" -o "$key_tmp"
  gpg --yes --dearmor -o "$keyring_tmp" "$key_tmp"
  sudo install -m 0644 "$keyring_tmp" "$output"
}

# Add known sources and update repository list
# Brave Browser
download_apt_file \
  https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
  /usr/share/keyrings/brave-browser-archive-keyring.gpg
download_apt_file \
  https://brave-browser-apt-release.s3.brave.com/brave-browser.sources \
  /etc/apt/sources.list.d/brave-browser-release.sources

# Cloudflare
download_apt_keyring \
  https://pkg.cloudflareclient.com/pubkey.gpg \
  /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

cloudflare_ubuntu_codename="$(lsb_release -cs)"
cloudflare_repo_codename="$cloudflare_ubuntu_codename"
case "$cloudflare_ubuntu_codename" in
  focal | jammy | noble) ;;
  resolute)
    # Temporary workaround until Cloudflare publishes a Resolute repository.
    # Community reports indicate the Noble repository works on Ubuntu 26.04.
    cloudflare_repo_codename="noble"
    echo "Cloudflare WARP does not yet publish a Resolute repository; using Noble as a temporary workaround." >&2
    ;;
  *)
    echo "Cloudflare WARP does not officially support Ubuntu codename '$cloudflare_ubuntu_codename'." >&2
    echo "Update the Cloudflare repository setup before installing cloudflare-warp." >&2
    exit 1
    ;;
esac

echo "deb [arch=amd64 \
  signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] \
  https://pkg.cloudflareclient.com/ ${cloudflare_repo_codename} main" |
  sudo tee /etc/apt/sources.list.d/cloudflare-client.list >/dev/null
sudo chmod 0644 /etc/apt/sources.list.d/cloudflare-client.list

# Spotify
download_apt_keyring \
  https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc \
  /etc/apt/keyrings/spotify.gpg
sudo rm -f /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb [signed-by=/etc/apt/keyrings/spotify.gpg] https://repository.spotify.com stable non-free" |
  sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null
sudo chmod 0644 /etc/apt/sources.list.d/spotify.list

# Kubernetes
KUBERNETES_MINOR_VERSION="v1.36"

download_apt_keyring \
  "https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR_VERSION}/deb/Release.key" \
  /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR_VERSION}/deb/ /" |
  sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
sudo chmod 0644 /etc/apt/sources.list.d/kubernetes.list

# Visual Studio Code
download_apt_keyring \
  https://packages.microsoft.com/keys/microsoft.asc \
  /usr/share/keyrings/microsoft.gpg

sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
sudo chmod 0644 /etc/apt/sources.list.d/vscode.sources

sudo tee /etc/apt/preferences.d/code >/dev/null <<'EOF'
Package: code
Pin: origin "packages.microsoft.com"
Pin-Priority: 9999
EOF
sudo chmod 0644 /etc/apt/preferences.d/code

# GitHub CLI
GITHUB_CLI_KEYRING_SHA256="6084d5d7bd8e288441e0e94fc6275570895da18e6751f70f057485dc2d1a811b"
github_cli_keyring_tmp="$apt_repo_tmp_dir/githubcli-archive-keyring.gpg"
curl --proto '=https' --tlsv1.2 -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  -o "$github_cli_keyring_tmp"

printf '%s  %s\n' "$GITHUB_CLI_KEYRING_SHA256" "$github_cli_keyring_tmp" |
  sha256sum -c -

github_cli_expected_fingerprints="$(
  printf '%s\n%s\n' \
    2C6106201985B60E6C7AC87323F3D4EA75716059 \
    7F38BBB59D064DBCB3D84D725612B36462313325 |
    sort
)"
github_cli_actual_fingerprints="$(
  gpg --show-keys --with-colons "$github_cli_keyring_tmp" |
    awk -F: '$1 == "pub" { primary_key = 1; next } primary_key && $1 == "fpr" { print $10; primary_key = 0 }' |
    sort
)"

if [ "$github_cli_actual_fingerprints" != "$github_cli_expected_fingerprints" ]; then
  echo "GitHub CLI keyring fingerprints did not match the expected official fingerprints." >&2
  echo "Expected:" >&2
  echo "$github_cli_expected_fingerprints" >&2
  echo "Actual:" >&2
  echo "$github_cli_actual_fingerprints" >&2
  exit 1
fi

sudo install -m 0644 "$github_cli_keyring_tmp" /etc/apt/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
  sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo chmod 0644 /etc/apt/sources.list.d/github-cli.list

sudo apt-get update

# Install packages
sudo env DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical NEEDRESTART_MODE=a \
  apt-get install -y \
  augeas-lenses \
  bind9-dnsutils \
  brave-browser \
  build-essential \
  clamav \
  clamav-daemon \
  cloudflare-warp \
  code \
  curl \
  docker.io \
  docker-buildx \
  docker-compose-v2 \
  file \
  gh \
  ghostty \
  git \
  git-secret \
  gnupg \
  htop \
  jq \
  libbz2-dev \
  libffi-dev \
  liblzma-dev \
  libpam-pwquality \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  libxml2-dev \
  libxmlsec1-dev \
  llvm \
  neovim \
  net-tools \
  tk-dev \
  ripgrep \
  scdaemon \
  shellcheck \
  software-properties-common \
  spotify-client \
  tmux \
  tree \
  ufw \
  unzip \
  vim \
  wget \
  xclip \
  xz-utils \
  zlib1g-dev

sudo systemctl enable --now docker

# Enable firewall
sudo ufw --force enable

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
if ! aws --version 2>/dev/null | grep -q '^aws-cli/2'; then
  aws_tmp_dir="$(mktemp -d)"
  cleanup_paths+=("$aws_tmp_dir")

  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o "$aws_tmp_dir/awscliv2.zip"

  unzip -q "$aws_tmp_dir/awscliv2.zip" -d "$aws_tmp_dir"

  sudo "$aws_tmp_dir/aws/install" \
    --bin-dir /usr/local/bin \
    --install-dir /usr/local/aws-cli
fi

# Install Helm from the official release archive.
HELM_VERSION="v4.1.4"
HELM_SIGNING_FINGERPRINT="BF888333D96A1C18E2682AAED79D67C9EC016739"
HELM_ARCHIVE="helm-${HELM_VERSION}-linux-amd64.tar.gz"

if ! command -v helm >/dev/null 2>&1 || ! helm version --short 2>/dev/null | grep -q "$HELM_VERSION"; then
  helm_tmp_dir="$(mktemp -d)"
  cleanup_paths+=("$helm_tmp_dir")

  curl -fsSL "https://get.helm.sh/${HELM_ARCHIVE}" \
    -o "$helm_tmp_dir/$HELM_ARCHIVE"
  curl -fsSL "https://get.helm.sh/${HELM_ARCHIVE}.sha256sum" \
    -o "$helm_tmp_dir/${HELM_ARCHIVE}.sha256sum"
  curl -fsSL "https://github.com/helm/helm/releases/download/${HELM_VERSION}/${HELM_ARCHIVE}.asc" \
    -o "$helm_tmp_dir/${HELM_ARCHIVE}.asc"
  curl -fsSL "https://github.com/helm/helm/releases/download/${HELM_VERSION}/${HELM_ARCHIVE}.sha256sum.asc" \
    -o "$helm_tmp_dir/${HELM_ARCHIVE}.sha256sum.asc"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/KEYS \
    -o "$helm_tmp_dir/helm-keys.asc"

  helm_gnupg_dir="$helm_tmp_dir/gnupg"
  mkdir -m 700 "$helm_gnupg_dir"
  gpg --homedir "$helm_gnupg_dir" --import "$helm_tmp_dir/helm-keys.asc"
  gpg --homedir "$helm_gnupg_dir" --list-keys --with-colons |
    grep -qx "fpr:::::::::${HELM_SIGNING_FINGERPRINT}:"

  gpg --homedir "$helm_gnupg_dir" --status-fd 1 \
    --verify "$helm_tmp_dir/${HELM_ARCHIVE}.asc" "$helm_tmp_dir/$HELM_ARCHIVE" |
    grep -q "^\[GNUPG:\] VALIDSIG ${HELM_SIGNING_FINGERPRINT} "
  gpg --homedir "$helm_gnupg_dir" --status-fd 1 \
    --verify "$helm_tmp_dir/${HELM_ARCHIVE}.sha256sum.asc" "$helm_tmp_dir/${HELM_ARCHIVE}.sha256sum" |
    grep -q "^\[GNUPG:\] VALIDSIG ${HELM_SIGNING_FINGERPRINT} "

  (
    cd "$helm_tmp_dir"
    sha256sum -c "${HELM_ARCHIVE}.sha256sum"
  )

  tar -xzf "$helm_tmp_dir/$HELM_ARCHIVE" -C "$helm_tmp_dir"
  sudo install -m 0755 "$helm_tmp_dir/linux-amd64/helm" /usr/local/bin/helm
fi

# Former Homebrew tools that are not already handled by APT above.
github_release_tmp_dir="$(mktemp -d)"
cleanup_paths+=("$github_release_tmp_dir")

install_github_release_tar() {
  local name="$1"
  local repo="$2"
  local version="$3"
  local asset_name="$4"
  local checksum_name="$5"
  local binary_path="$6"
  local version_arg="${7:---version}"
  local install_dir="${8:-}"
  local top_level_dir="${binary_path%%/*}"
  local relative_binary_path="${binary_path#*/}"

  if command -v "$name" >/dev/null 2>&1 && "$name" "$version_arg" 2>/dev/null | grep -q "$version"; then
    if [ -z "$install_dir" ]; then
      echo "$name $version already installed."
      return
    fi

    local installed_binary
    local expected_binary
    installed_binary="$(readlink -f "$(command -v "$name")")"
    expected_binary="$(readlink -m "$install_dir/$relative_binary_path")"
    if [ "$installed_binary" = "$expected_binary" ]; then
      echo "$name $version already installed."
      return
    fi
  fi

  local release_base_url="https://github.com/${repo}/releases/download/v${version}"
  local archive="$github_release_tmp_dir/$asset_name"
  local checksums="$github_release_tmp_dir/${name}.checksums"
  curl -fsSL "${release_base_url}/${asset_name}" -o "$archive"

  if [[ "$checksum_name" != sha256:* && ! "$checksum_name" =~ ^[[:xdigit:]]{64}$ ]]; then
    curl -fsSL "${release_base_url}/${checksum_name}" -o "$checksums"
  fi

  (
    cd "$github_release_tmp_dir"
    local actual_checksum
    actual_checksum="$(sha256sum "$archive" | awk '{print tolower($1)}')"

    local asset_regex
    asset_regex="$(printf '%s' "$asset_name" | sed 's/[][\/.^$*+?{}()|]/\\&/g')"

    local expected_checksum
    if [[ "$checksum_name" == sha256:* ]]; then
      expected_checksum="${checksum_name#sha256:}"
    elif [[ "$checksum_name" =~ ^[[:xdigit:]]{64}$ ]]; then
      expected_checksum="$checksum_name"
    else
      expected_checksum="$(
        grep -E "^[[:xdigit:]]{64}[[:space:]]+\\*?${asset_regex}$" "$checksums" |
          awk 'NR == 1 { print tolower($1) }' ||
          true
      )"

      if [ -z "$expected_checksum" ] &&
        grep -E "^${asset_regex}[[:space:]].*[[:space:]]${actual_checksum}([[:space:]]|$)" "$checksums" >/dev/null; then
        expected_checksum="$actual_checksum"
      fi
    fi

    if [ -z "$expected_checksum" ]; then
      echo "$asset_name: SHA-256 checksum not found in $checksum_name" >&2
      exit 1
    fi

    if [ "$actual_checksum" != "$expected_checksum" ]; then
      echo "$asset_name: checksum mismatch" >&2
      echo "expected: $expected_checksum" >&2
      echo "actual:   $actual_checksum" >&2
      exit 1
    fi
    echo "$asset_name: OK"
  )

  local extract_dir="$github_release_tmp_dir/${name}"
  mkdir -p "$extract_dir"
  tar -xzf "$archive" -C "$extract_dir"

  if [ -n "$install_dir" ]; then
    sudo rm -rf "$install_dir"
    sudo mkdir -p "$install_dir"
    sudo cp -a "$extract_dir/$top_level_dir/." "$install_dir/"
    sudo ln -sf "$install_dir/$relative_binary_path" "/usr/local/bin/$name"
  else
    sudo install -m 0755 "$extract_dir/$binary_path" "/usr/local/bin/$name"
  fi
}

# To update: check each repository's GitHub Releases page, update the version
# and asset names. URLs are derived from the repo, version, and asset names.

# balena CLI: https://github.com/balena-io/balena-cli/releases
# GitHub publishes the asset hash as a release asset digest.
BALENA_CLI_VERSION="25.1.3"
install_github_release_tar \
  balena \
  balena-io/balena-cli \
  "$BALENA_CLI_VERSION" \
  "balena-cli-v${BALENA_CLI_VERSION}-linux-x64-standalone.tar.gz" \
  sha256:09c5d6d280afe30fcf7633df2ef1e70078ebfb4ed649beeca40fbaf3c4fbefce \
  balena/bin/balena \
  version \
  /opt/balena-cli
balena version

# k9s: https://github.com/derailed/k9s/releases
# Hashes are published in the release asset named checksums.sha256.
install_github_release_tar \
  k9s \
  derailed/k9s \
  0.50.18 \
  "k9s_Linux_amd64.tar.gz" \
  checksums.sha256 \
  k9s \
  version

# flux: https://github.com/fluxcd/flux2/releases
# Hashes are published in flux_<version>_checksums.txt.
FLUX_VERSION="2.8.5"
install_github_release_tar \
  flux \
  fluxcd/flux2 \
  "$FLUX_VERSION" \
  "flux_${FLUX_VERSION}_linux_amd64.tar.gz" \
  "flux_${FLUX_VERSION}_checksums.txt" \
  flux

# saml2aws: https://github.com/Versent/saml2aws/releases
# Hashes are published in saml2aws_<version>_checksums.txt.
SAML2AWS_VERSION="2.36.19"
install_github_release_tar \
  saml2aws \
  Versent/saml2aws \
  "$SAML2AWS_VERSION" \
  "saml2aws_${SAML2AWS_VERSION}_linux_amd64.tar.gz" \
  "saml2aws_${SAML2AWS_VERSION}_checksums.txt" \
  saml2aws

# yq: https://github.com/mikefarah/yq/releases
# Hashes are published in the release asset named checksums.
install_github_release_tar \
  yq \
  mikefarah/yq \
  4.52.5 \
  "yq_linux_amd64.tar.gz" \
  checksums \
  yq_linux_amd64

# Install vim-sleuth as a native Neovim package.
# Pin the checkout to an expected commit instead of tracking a moving branch.
VIM_SLEUTH_VERSION="v2.0"
VIM_SLEUTH_COMMIT="1d25e8e5dc4062e38cab1a461934ee5e9d59e5a8"
VIM_SLEUTH_DIR="$HOME/.local/share/nvim/site/pack/plugins/start/vim-sleuth"

mkdir -p "$(dirname "$VIM_SLEUTH_DIR")"
if [ ! -d "$VIM_SLEUTH_DIR/.git" ]; then
  git clone --filter=blob:none https://github.com/tpope/vim-sleuth.git "$VIM_SLEUTH_DIR"
fi

git -C "$VIM_SLEUTH_DIR" remote set-url origin https://github.com/tpope/vim-sleuth.git
git -C "$VIM_SLEUTH_DIR" fetch --tags --force origin "$VIM_SLEUTH_VERSION"
git -C "$VIM_SLEUTH_DIR" checkout --detach "$VIM_SLEUTH_COMMIT"

if [ "$(git -C "$VIM_SLEUTH_DIR" rev-parse HEAD)" != "$VIM_SLEUTH_COMMIT" ]; then
  echo "Error: vim-sleuth checkout did not match expected commit." >&2
  exit 1
fi

# Require git commit signing
git config --global commit.gpgsign true

# Install GPG configuration
# shellcheck disable=SC2016
grep 'export GPG_TTY=$(tty)' ~/.bashrc || echo 'export GPG_TTY=$(tty)' >>~/.bashrc

# Replicate MacOS pbcopy using xclip
grep "alias pbcopy='xclip -selection clipboard'" ~/.bashrc || echo "alias pbcopy='xclip -selection clipboard'" >>~/.bashrc

# Do some environment-specific installations
[[ "${XDG_CURRENT_DESKTOP:-}" =~ "GNOME" ]] &&
  sudo env DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical NEEDRESTART_MODE=a \
    apt-get install -y \
    gnome-tweaks

# Configure VS Code user settings.
# This disables built-in AI features, extension recommendations, and automatic
# extension updates while keeping Workspace Trust enabled with a one-time prompt.
# The jq merge preserves any unrelated settings already present in settings.json.
VSCODE_SETTINGS_FILE="$HOME/.config/Code/User/settings.json"
mkdir -p "$(dirname "$VSCODE_SETTINGS_FILE")"

if [ ! -f "$VSCODE_SETTINGS_FILE" ]; then
  printf '{}\n' >"$VSCODE_SETTINGS_FILE"
fi

vscode_settings_tmp="$(mktemp)"
cleanup_paths+=("$vscode_settings_tmp")

jq \
  'if type == "object" then . else {} end
  * {
    "chat.disableAIFeatures": true,
    "extensions.ignoreRecommendations": true,
    "extensions.autoUpdate": false,
    "extensions.autoCheckUpdates": false,
    "security.workspace.trust.enabled": true,
    "security.workspace.trust.startupPrompt": "once"
  }' \
  "$VSCODE_SETTINGS_FILE" >"$vscode_settings_tmp"

mv "$vscode_settings_tmp" "$VSCODE_SETTINGS_FILE"

# Yank to clipboard by default in neovim
mkdir -p "$HOME/.config/nvim"
cat << EOF > "$HOME/.config/nvim/init.lua"
vim.opt.autoread = true
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.relativenumber = true

vim.api.nvim_create_autocmd(
  { "FocusGained", "BufEnter", "CursorHold" },
  { command = "checktime" }
)
EOF

echo 'Done.'
