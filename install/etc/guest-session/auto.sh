#! /bin/bash

gsettings set org.cinnamon.desktop.lockdown disable-lock-screen true
TITLE='Session Temporaire - Réseau des Biblio&Ludothèques de Watermael-Boitsfort'
TEXT="<big>Bonjour,</big> \n\n
<big><span color=\"red\">Cet ordinateur sera réinitialisé après déconnexion ou redémarrage.</span></big>\n\n\
<big>Pensez à <b>sauvegarder vos données</b> !</big> \n\
Utilisez pour ce faire un support amovible comme une clef USB ou une solution de stockage en ligne. \n\
Vous pouvez sinon utiliser le répertoire 'Sauvegarde' qui est partagé entre tous les utilisateurs (non recommandé : vos fichiers seront publics !).\n\n\
<big>Pour vous déconnecter, utilisez le bouton situé dans le coin inférieur droit de l'écran.</big>\n\n\
<big><b>RAPPEL :</b> La machine est à votre disposition pour 30 minutes, passé ce délai il pourra vous être demandé de céder votre place.</big>"
{ sleep 4; zenity --info --width=600 --no-wrap --title="$TITLE" --text="$TEXT"; } &
