#!/bin/zsh
set -euo pipefail

# ─── Configuration macOS — Gorditos ─────────────────────────
# Applique les réglages système pour laptops d'entreprise
# Usage : ./macos.sh
# Peut être exécuté seul ou appelé depuis setup.sh
# ─────────────────────────────────────────────────────────────

LOG_FILE="${LOG_FILE:-$HOME/.gorditos-setup.log}"

info()  { printf "\e[32m[INFO]\e[0m  %s\n" "$*" | tee -a "$LOG_FILE"; }
warn()  { printf "\e[33m[WARN]\e[0m  %s\n" "$*" | tee -a "$LOG_FILE"; }
ok()    { printf "\e[32m[OK]\e[0m    %s\n" "$*" | tee -a "$LOG_FILE"; }

info "Finder"
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowTabView -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
ok "Finder configuré"

info "Dock"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.4
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-recents -bool false
ok "Dock configuré"

info "Trackpad"
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
ok "Trackpad configuré"

info "Clavier"
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
ok "Clavier configuré"

info "Captures d'écran"
SCREENSHOTS_DIR="$HOME/Desktop/Captures"
mkdir -p "$SCREENSHOTS_DIR"
defaults write com.apple.screencapture location -string "$SCREENSHOTS_DIR"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true
ok "Captures d'écran configurées"

info "Barre de menus"
defaults write com.apple.menuextra.battery ShowPercent -string "YES"
defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
ok "Barre de menus configurée"

info "Redémarrage des services..."
killall Finder Dock SystemUIServer 2>/dev/null || true
ok "Terminé"
