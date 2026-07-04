#!/bin/zsh
echo "
 ▗▄▄▖ ▗▄▖ ▗▄▄▖ ▗▄▄▄ ▗▄▄▄▖▗▄▄▄▖▗▄▖  ▗▄▄▖
▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌  █  █    █ ▐▌ ▐▌▐▌
▐▌▝▜▌▐▌ ▐▌▐▛▀▚▖▐▌  █  █    █ ▐▌ ▐▌ ▝▀▚▖
▝▚▄▞▘▝▚▄▞▘▐▌ ▐▌▐▙▄▄▀▗▄█▄▖  █ ▝▚▄▞▘▗▄▄▞▘
             2024 WAREZ
"

set -euo pipefail

# Installation des Command Line Tools de Xcode
# xcode-select --install

# finder : show tab bar, show path bar, show status bar

# Vérifier si Homebrew est installé
if ! command -v brew &> /dev/null; then
    echo "Homebrew n'est pas installé. Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Mettre à jour Homebrew
brew update

# Installer des applications
brew install dockutil

brew install --cask google-chrome
dockutil --add "/Applications/Google Chrome.app" --position 3

brew install --cask google-drive
dockutil --add "/Applications/Google Drive.app" --position 4

brew install --cask microsoft-office
dockutil --add "/Applications/Microsoft Word.app" --position 5
dockutil --add "/Applications/Microsoft Excel.app" --position 6

brew install --cask adobe-acrobat-pro
dockutil --add "/Applications/Adobe Acrobat Pro.app" --position 7

brew install --cask slack
dockutil --add "/Applications/Slack.app" --position 8

brew install --cask zoom
dockutil --add "/Applications/zoom.us.app" --position 9

brew install --cask spotify
dockutil --add "/Applications/Spotify.app" --position 10

# Installer des utilitaires
brew install wget

# Message de fin
echo "Installation terminée"
