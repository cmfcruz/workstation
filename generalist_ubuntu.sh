#!/usr/bin/env bash

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

# Install packages using Homebrew
brew install \
    cue-lang/tap/cue \
    derailed/k9s/k9s \
    fluxcd/tap/flux \
    git-secret \
    terragrunt \
    yq

# Install Pyenv
curl https://pyenv.run | bash
grep "export PATH=$PATH:/home/cmfcruz/.pyenv/bin" ~/.zshrc || echo "export PATH=$PATH:/home/cmfcruz/.pyenv/bin" >> ~/.zshrc
export PATH=$PATH:/home/cmfcruz/.pyenv/bin

# Add the Kubernetes apt repository
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list


# Install Github CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Add Terraform apt repository
wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list


# Install packages using apt
sudo apt update \
&& sudo apt install -y \
    docker \
    docker.io \
    gh \
    kubectl \
    jq \
    shellcheck \
    terraform \
    tree \
    wget \
    vim \
    visual-studio-code \
    zsh

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

# Show current working directory in prompt
grep 'export PS1="%m %~%# "' ~/.zshrc || echo 'export PS1="%m %~%# "' >> ~/.zshrc

echo 'Done.'
