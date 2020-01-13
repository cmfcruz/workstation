#!/usr/bin/env zsh

# Install Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Change shell to Z Shell
chsh -s /bin/zsh

# Install git flow
brew install git-flow

# Install Zsh Autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc

# Install Starship
brew install starship
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
eval "$(starship init zsh)"

# Install Powerline Fonts
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts

# Install Pyenv
brew install pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshrc

# Install AWS CLI
pip install awscli

# Install Kubernetes CLI
brew install kubectl

# Install Hyperkit
brew install hyperkit

# Install Minikube
brew install minikube

# Install Docker CLI
brew install docker

# Install Visual Studio Code
brew cask install visual-studio-code

# Install Google Chrome
brew cask install google-chrome

# Install KeepassXC
brew cask install keepassxc

echo 'Done.'
