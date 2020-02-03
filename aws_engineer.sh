#!/usr/bin/env zsh

# Install Homebrew
test -f /usr/local/bin/brew || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Change shell to Z Shell
chsh -s /bin/zsh

# Install git flow
brew install git-flow

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

# Install Pyenv
brew install pyenv
grep 'export PYENV_ROOT="$HOME/.pyenv"' ~/.zshrc || echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
grep 'export PATH="$PYENV_ROOT/bin:$PATH"' ~/.zshrc || echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
grep 'eval "$(pyenv init -)"' ~/.zshrc || echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshrc
eval "$(pyenv init -)"
pyenv install 3.7.6

# Install AWS CLI
pip3 install awscli

# Install aws-iam-authenticator for EKS
brew install aws-iam-authenticator

# Install GPG
brew install gnupg
grep 'export GPG_TTY=$(tty)' ~/.zshrc || echo 'export GPG_TTY=$(tty)' >> ~/.zshrc

# Install Terraform
brew install terraform

# Install Kubernetes CLI
brew install kubectl

# Install Help
brew install helm

# Install K9s CLI
brew install derailed/k9s/k9s

# Install Hyperkit
brew install hyperkit

# Install Minikube
brew install minikube

# Install Docker CLI
brew install docker

# Install Virtualbox
brew cask install virtualbox

# Install Vagrant
brew cask install vagrant

# Install Visual Studio Code
brew cask install visual-studio-code

# Install Google Chrome
brew cask install google-chrome

# Install KeepassXC
brew cask install keepassxc

# Update existing packages
brew update
brew upgrade
brew cask upgrade

echo 'Done.'
