#! /bin/bash

gsettings set org.cinnamon.desktop.lockdown disable-lock-screen true
TITLE='Session Temporaire'
TEXT="Bonjour, cet ordinateur sera réinitialisé après déconnexion ou redémarrage.\n\n\
Pensez à sauvegarder vos données ! \n\
Vous pouvez utiliser le répertoire public /var/guest-data (Raccourci 'Sauvegarde') ou un support amovible comme une clef USB\n\n\
RAPPEL : La machine est à votre disposition pour 30 minutes, passé ce délais il pourra vous être demandé de céder votre place"
{ sleep 4; zenity --warning --no-wrap --title="$TITLE" --text="$TEXT"; } &
