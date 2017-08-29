#! /bin/bash

# on corrige les répertoires par défaut
signets="$HOME/.config/gtk-3.0/bookmarks"
match1=$(printf '%s\n' "/home/modele" | sed 's/[[\.*^$/]/\\&/g')
replace1=$(printf '%s\n' "$HOME" | sed 's/[[\.*^$/]/\\&/g')
sed -i -e "s/$match1/$replace1/g" $signets

# on désactive l'écran de veille
gsettings set org.cinnamon.desktop.lockdown disable-lock-screen true

# on désactive le message d'accueil de la session temporaire 
# (modifié dans /etc/guest-session/auto.sh)
touch $HOME/.skip-guest-warning-dialog
