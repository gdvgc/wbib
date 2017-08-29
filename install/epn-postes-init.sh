#! /bin/bash

#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  

# fichier de configuration express post installation de Linux Mint 18.2 Cinnamon
# on active la session "invité" qui permet un nettoyage automatique de la session utilisateur
# on créé un utilisateur "modele" qui sert de base au compte invité

# variables globales
userhome=/home/modele
# on s'assure de travailler relativement au dossier racine du script d'installation
workdir="$( cd "$(dirname "$0")" ; pwd -P )"

# on logue toutes les actions :
LOG_FILE=${workdir}/configure
touch ${LOG_FILE}
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

# un générateur de séparateur
# la fonction répète le motif fourni en paramètre
function printline () {
	c=$1
	printf "%$(tput cols)s" "" | sed s/' '/"${c:=_}"/g | cut -c1-$(tput cols)
}

printline %
echo $(date +"%Y%m%d_%H%M%S")
printline %

# à lancer avec les droits de superutilisateur 
if [ "$(id -u)" != "0" ]; then
	printline %
	echo "Ce script doit être lancé avec les droits de superutilisateur"
	printline %
	exit 1
fi

# fonction stop ou encore utilisée pour toutes les étapes du script (debug)
fn_stop_ou_encore () {
	printline =
    echo $1
	echo "Oui ou Non ?"
	read stop_encore
	case $stop_encore in
	O|o|Y|y)
		$2
		printline %
		;;
	N|n)
		echo "Alors on saute l'étape \"$1\"";
		;;
	*)
		echo "bon, on reprend"
		fn_stop_ou_encore "$1" $2;
		;;
	esac
    printline %
}


# nommage du poste de travail
# définition du type de poste
fn_type_poste () {
	printline =
	echo "type de poste mobile (M) ou fixe (F) ?"
	read type_poste
	case $type_poste in
	m|M)
		echo "poste mobile"
		type_poste="M"
		;;
	f|F)
		echo "poste fixe"
		type_poste="F"
		;;
	*)
		echo "mauvaise saisie, M ou F ?"
		fn_type_poste;
		;;
	esac
}

# définition du numéro de poste
fn_num_poste (){
	# si le type de poste n'est pas défini, on renvoie à la fonction appropriée
	if [ -z "$type_poste" ]; then
		fn_type_poste;
	fi
	printline =
	echo "numéro de poste : epnWBib-"$type_poste"xx"
	read num_poste
	if [[ $num_poste =~ ^[0-9]{,2}$ ]] ;
	then 
		echo "poste numéro "$num_poste
	else
		echo "mauvaise saisie, indiquez un numéro"
		fn_num_poste;
	fi
}

# validation et sauvegarde du nom de poste 
fn_valide_nom_poste () {
	printline %
	echo "le nom du poste sera : $nom_poste est-ce correct ? (Y/N O/N)"
	read nom_valide
	case $nom_valide in
	O|o|Y|y)
		echo "ok ! on écrit le nom du poste dans /etc/hostname et dans /etc/hosts"
        hostname_original=$(echo $HOSTNAME)
		echo $nom_poste > /etc/hostname
        fichier_hosts="/etc/hosts"
        sed -i -e "s/$hostname_original/$nom_poste/g" $fichier_hosts
		printline %
		;;
	N|n)
		echo "Alors on recommence !"
		fn_nommer_poste;
		;;
	*)
		echo "bon, on reprend"
		fn_valide_nom_poste;
		;;
	esac
}

# définition du nom du poste
fn_nommer_poste () {
	printline %
	echo "on définit le nom du poste :"
	echo "-> O|o|Y|y pour un nom formaté : epnWBib-[type][numéro]"
	echo "-> N|n pour un nom libre"
	read nom_fixe
	case $nom_fixe in
	O|o|Y|y)
		fn_type_poste
		fn_num_poste
		unset nom_poste
		nom_poste="epnWBib-"$type_poste$num_poste
		;;
	N|n)
		printline =
		echo "Entrez le nom désiré pour le poste"
		unset nom_poste
		read nom_poste
		;;
	*)
		echo "bon, on reprend"
		fn_valide_nom_poste;
		;;
	esac
	fn_valide_nom_poste
}


fn_stop_ou_encore "on définit le nom du poste" fn_nommer_poste;

#on fixe les dépôts logiciels
fn_nouveaux_depots () {

    printline %
    liste_base="/etc/apt/sources.list.d/official-package-repositories.list"

    if [ -f $liste_base ];
    then
       echo "Le fichier $list_base existe, on le sauvegarde."
       mv $list_base $liste_base $list_base $liste_base".orig"
       cp $workdir/etc/apt/sources.list.d/official-package-repositories.list /etc/apt/sources.list.d/
    else
       echo "File $list_base does not exist."
       cp $workdir/etc/apt/sources.list.d/official-package-repositories.list /etc/apt/sources.list.d/
    fi
}

fn_stop_ou_encore "on fixe les dépôts logiciels" fn_nouveaux_depots;

# mise à jour du système
# apt-get -y répond par l'affirmative aux questions du gestionnaire de paquets
fn_maj_systeme () {    
    echo "mise à jour du système (apt-get update && apt-get -y dist-upgrade)"
    apt-get -q update
    apt-get -qy dist-upgrade
}
fn_stop_ou_encore "Mise à jour du système" fn_maj_systeme;

# echo "ajout de l'utilisateur invité" 
# Depuis la version 18.2 Mint utilise LightDM par défaut, plus besoin de l'installer, on copie tout de même la config et le profil

fn_ajout_invite () {
    # copie de la configuration de lightDM
    cp -rf $workdir/etc/lightdm /etc/

    # on crée un utilisateur "modèle" qui  sert à définir le compte invité
    # le mot de passe est généré avec mkpasswd et utilse crypt(3)
    echo "on crée l'utilisateur 'modele' qui sert de config de base pour l'invité son pwd est crypté"
    useradd -U -s /bin/bash -d /home/modele -m -p bMGU00do6JvyU modele

    # copie du home de modele
    cp -rf $workdir/$userhome/. $userhome/
    # on rend les lanceurs exécutables
    chmod +x $userhome/Bureau/*

    # copie des paramètres de la session invitée
    cp -rf $workdir/etc/guest-session /etc/
    chmod 775 /etc/guest-session/*.sh # 755 ne suffit pas pour auto.sh

    # on crée un lien symbolique vers le home de modele pour l'utilisateur invité
    ln -s $userhome /etc/guest-session/skel 
     

    # active-t-on un répertore persistant ?
    fn_donnees_persistantes () {
	    printline %
	    echo "active-t-on un répertore persistant ? ? (Y/N O/N)"
	    read persistant
	    case $persistant in
	    O|o|Y|y)
		    echo "ok ! on crée /var/guest-data et on l'ajoute aux favoris de Gnome/Cinnamon"
		    mkdir -m 0777 /var/guest-data
            ln -s /var/guest-data $userhome/Sauvegarde
		    echo "file://$userhome/Sauvegarde" >> $userhome/.config/gtk-3.0/bookmarks
		    printline %
		    ;;
	    N|n)
		    echo "Pas de données persistantes alors (penser à éditer /etc/guest-session/auto.sh pour le message d'accueil)"
		    ;;
	    *)
		    echo "bon, on reprend"
		    fn_donnees_persistantes;
		    ;;
	    esac
    }
    fn_donnees_persistantes

    # On rend à l'utilisateur modele la propriété de ses fichiers
    chown -R modele:modele $userhome 
}

fn_stop_ou_encore "Ajout de l'utilisateur invité" fn_ajout_invite;

# installation du lecteur de cartes d'identité électronique

fn_install_eid () {
    echo " installation du lecteur de cartes d'identité électronique"
    dpkg -i $workdir/deb/eid-archive_2017.4_all.deb 
    apt-get -q update
    apt-get -qy install eid-mw eid-viewer libacr38u
}
fn_stop_ou_encore "installation du lecteur de cartes d'identité électronique" fn_install_eid

# installation des codecs multimédia, d'inkscape et scribus du man en français et ajout du protocole ssh
fn_install_sup () {
    echo "installation des codecs multimédia, d'inkscape, scribus, du man en français, de ssh, de l'ocr et des polices m$"
    apt-get -y install ubuntu-restricted-extras inkscape scribus ttf-mscorefonts-installer tesseract-ocr tesseract-ocr-fra manpages-fr ssh

    # interdire à tous d'utiliser ssh (n'autoriser que epn-admin)
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
    echo "AllowUsers epn-admin" >> /etc/ssh/sshd_config

    service ssh restart
}
fn_stop_ou_encore "installation des codecs multimédia, d'inkscape, scribus, du man en français, de ssh, de l'ocr et des polices m$" fn_install_sup;

#copie de l'arrière-plan de lightdm (écran d'accueil)
fn_copie_wallpaper () {
    cp $workdir/img/wallpaper-wb.jpg /usr/share/backgrounds/linuxmint/wallpaper-wb.jpg
    chmod 644 /usr/share/backgrounds/linuxmint/wallpaper-wb.jpg
    # mise à jour du lien symbolique
    ln -sf /usr/share/backgrounds/linuxmint/wallpaper-wb.jpg /usr/share/backgrounds/linuxmint/default_background.jpg 
}
fn_stop_ou_encore "copie de l'arrière-plan de lightdm (écran d'accueil)" fn_copie_wallpaper;

#mise à jour du système
fn_stop_ou_encore "Mise à jour du système" fn_maj_systeme;

printline %
printline %
echo "\nconfiguration terminée pour $nom_poste\n"
printline %
printline %

cp ${LOG_FILE} ${LOG_FILE}-${nom_poste}-$(date +"%Y%m%d_%H%M%S").log
rm ${LOG_FILE}
