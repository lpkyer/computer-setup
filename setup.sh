#!/bin/zsh
set -euo pipefail

echo "
 ▗▄▄▖ ▗▄▖ ▗▄▄▖ ▗▄▄▄ ▗▄▄▄▖▗▄▄▄▖▗▄▖  ▗▄▄▖
▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌  █  █    █ ▐▌ ▐▌▐▌
▐▌▝▜▌▐▌ ▐▌▐▛▀▚▖▐▌  █  █    █ ▐▌ ▐▌ ▝▀▚▖
▝▚▄▞▘▝▚▄▞▘▐▌ ▐▌▐▙▄▄▀▗▄█▄▖  █ ▝▚▄▞▘▗▄▄▞▘
             2024 WAREZ
"

# ─── Configuration ───────────────────────────────────────────
LOG_FILE="$HOME/.gorditos-setup.log"
BREWFILE="$(cd "$(dirname "$0")" && pwd)/Brewfile"

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

if [[ ! -f "$BREWFILE" ]]; then
  error "Brewfile introuvable : $BREWFILE"
  exit 1
fi

info "Installation des applications (cette étape peut prendre du temps)..."
brew bundle --file="$BREWFILE" --no-lock 2>&1 | tee -a "$LOG_FILE" || true
ok "Applications installées"

# ─── Étape 4 : Configuration macOS ──────────────────────────
step "Configuration macOS"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/macos.sh" ]]; then
  # shellcheck source=macos.sh
  source "$SCRIPT_DIR/macos.sh"
  ok "Préférences système appliquées"
else
  warn "macos.sh introuvable — configuration système ignorée"
fi

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
