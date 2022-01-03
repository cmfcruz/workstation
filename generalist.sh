#!/usr/bin/env zsh

# Install Homebrew
test -f /usr/local/bin/brew || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install iterm2
brew install --cask iterm2

# Change shell to Z Shell
chsh -s /bin/zsh

# Install Zsh Autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
grep 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' ~/.zshrc || echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc

# Install Starship
brew install starship
grep 'eval "$(starship init zsh)"' ~/.zshrc || echo 'eval "$(starship init zsh)"' >> ~/.zshrc
eval "$(starship init zsh)"

# Install Powerline Fonts
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts

# Install Github CLI
brew install gh

# Install cuelang
brew install cue-lang/tap/cue

# Install Pyenv
brew install pyenv
grep 'export PYENV_ROOT="$HOME/.pyenv"' ~/.zshrc || echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
grep 'export PATH="$PYENV_ROOT/bin:$PATH"' ~/.zshrc || echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
grep 'eval "$(pyenv init -)"' ~/.zshrc || echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshrc
eval "$(pyenv init -)"
pyenv install 3.8.12

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# Install AWS CLI
brew install awscli

# Install GPG
brew install gnupg
grep 'export GPG_TTY=$(tty)' ~/.zshrc || echo 'export GPG_TTY=$(tty)' >> ~/.zshrc

# Install Terraform
brew install terraform

# Install Terragrunt
brew install terragrunt

# Install Kubernetes CLI
brew install kubectl

# Install Flux CLI
brew install fluxcd/tap/flux

# Install K9s CLI
brew install derailed/k9s/k9s

# Install Visual Studio Code
brew install --cask visual-studio-code

# Install Google Chrome
brew install --cask google-chrome

# Install Docker Desktop
brew install --cask docker

# Update existing packages
brew update
brew upgrade
brew upgrade --cask

echo 'Done.'
