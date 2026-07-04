#!/bin/zsh
set -euo pipefail

echo "
  ╔═══════════════════════════╗
  ║       L . P   K Y E R    ║
  ║   Script d'installation   ║
  ╚═══════════════════════════╝
"

# ─── Configuration ───────────────────────────────────────────
LOG_FILE="$HOME/.gorditos-setup.log"

# ─── Logging ─────────────────────────────────────────────────
info()  { printf "\e[34m[INFO]\e[0m  %s\n" "$*" | tee -a "$LOG_FILE"; }
ok()    { printf "\e[32m[OK]\e[0m    %s\n" "$*" | tee -a "$LOG_FILE"; }
warn()  { printf "\e[33m[WARN]\e[0m  %s\n" "$*" | tee -a "$LOG_FILE"; }
error() { printf "\e[31m[ERREUR]\e[0m %s\n" "$*" | tee -a "$LOG_FILE"; }

# ─── Traçage des étapes ──────────────────────────────────────
STEP=0
TOTAL_STEPS=5

step() {
  STEP=$((STEP + 1))
  printf "\n┌─ \e[1;36m[%d/%d] %s\e[0m\n" "$STEP" "$TOTAL_STEPS" "$*" | tee -a "$LOG_FILE"
}

# ─── Nettoyage en cas d'erreur ───────────────────────────────
cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    printf "\n\e[31m❌ Erreur à l'étape %d/%d.\e[0m\n" "$STEP" "$TOTAL_STEPS"
    printf "   Consultez le log : %s\n" "$LOG_FILE"
  fi
}
trap cleanup EXIT

# ─── Cache sudo (nécessaire pour Homebrew installer) ────────
info "Authentification requise pour l'installation..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &

# ─── Début ───────────────────────────────────────────────────
echo "  Lancement de l'installation Gorditos..."
echo "  Log : $LOG_FILE"
echo "" | tee -a "$LOG_FILE"
date | tee -a "$LOG_FILE"

# ─── Étape 1 : Prérequis ────────────────────────────────────
step "Préparation"

# Détection Apple Silicon
if [[ $(uname -m) == "arm64" ]]; then
  info "Apple Silicon détecté"
  HOMEBREW_PREFIX="/opt/homebrew"
else
  info "Intel détecté"
  HOMEBREW_PREFIX="/usr/local"
fi

# Connexion Internet
if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
  error "Pas de connexion Internet. Abandon."
  exit 1
fi
ok "Connexion Internet OK"

# ─── Étape 2 : Homebrew ─────────────────────────────────────
step "Homebrew"

if ! command -v brew &>/dev/null; then
  info "Installation de Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
  ok "Homebrew installé"
else
  ok "Homebrew déjà présent"
fi

info "Mise à jour de Homebrew..."
brew update 2>&1 | tee -a "$LOG_FILE" || true
ok "Homebrew à jour"

# ─── Étape 3 : Applications ─────────────────────────────────
step "Applications"

info "Installation des applications (cette étape peut prendre du temps)..."

install_cask() {
  local name="$1"
  if brew list --cask "$name" &>/dev/null 2>&1; then
    ok "$name déjà installé"
  else
    info "Installation de $name..."
    brew install --cask "$name" 2>&1 | tee -a "$LOG_FILE" || true
  fi
}

install_formula() {
  local name="$1"
  if brew list "$name" &>/dev/null 2>&1; then
    ok "$name déjà installé"
  else
    info "Installation de $name..."
    brew install "$name" 2>&1 | tee -a "$LOG_FILE" || true
  fi
}

install_cask "google-chrome"
install_cask "google-drive"
install_cask "microsoft-office"
install_cask "adobe-acrobat-pro"
install_cask "slack"
install_cask "zoom"
install_cask "spotify"
install_cask "rectangle"

install_formula "dockutil"
install_formula "wget"

ok "Applications installées"

# ─── Étape 4 : Configuration macOS ──────────────────────────
step "Configuration macOS"

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
ok "Préférences système appliquées"

# ─── Étape 5 : Dock ─────────────────────────────────────────
step "Barre d'applications (Dock)"

if ! command -v dockutil &>/dev/null; then
  warn "dockutil pas installé — configuration du Dock ignorée"
else
  DOCK_APPS=(
    "Google Chrome.app"
    "Google Drive.app"
    "Microsoft Word.app"
    "Microsoft Excel.app"
    "Adobe Acrobat Pro.app"
    "Slack.app"
    "zoom.us.app"
    "Spotify.app"
    "Rectangle.app"
  )

  pos=3
  for app in "${DOCK_APPS[@]}"; do
    if [[ -d "/Applications/$app" ]]; then
      dockutil --add "/Applications/$app" --position $pos --no-restart 2>/dev/null || true
      pos=$((pos + 1))
    else
      warn "Application introuvable : $app"
    fi
  done

  killall Dock 2>/dev/null || true
  ok "Dock configuré"
fi

# ─── Fin ─────────────────────────────────────────────────────
printf "\n\e[1;32m"
echo "  ✅ Installation terminée avec succès !"
printf "\e[0m"
echo ""
echo "  📍 Pour appliquer tous les changements :"
echo "     1. Déconnectez-vous (menu Pomme → Déconnexion)"
echo "     2. Reconnectez-vous"
echo ""
echo "  📄 Log : $LOG_FILE"
