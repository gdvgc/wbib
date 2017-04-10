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

# fichier de configuration express post installation de Linux Mint 18.1 Cinnamon
# on active la session "invité" qui permet un nettoyage automatique de la session utilisateur
# on créé un utilisateur "modele" qui sert de base au compte invité

# variables globales
userhome=/home/modele
workdir="$( cd "$(dirname "$0")" ; pwd -P )"

# on logue toutes les actions :
LOG_FILE=${workdir}/configure-$(date +"%Y%m%d_%H%M%S").log
touch ${LOG_FILE}
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

#{
#	apt-get update
#	apt-get -y dist-upgrade
#} &> /dev/null

# un générateur de séparateur
# la fonction répète le motif fourni en paramètre
function printline () {
	c=$1
	printf "%$(tput cols)s" "" | sed s/' '/"${c:=_}"/g | cut -c1-$(tput cols)
}

# à lancer avec les droits de super utilisateur
if [ "$(id -u)" != "0" ]; then
	printline %
	echo "Ce script doit être lancé avec les droits de superutilisateur"
	printline %
	exit 1
fi

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
		echo "ok ! on écrit le nom du poste dans /etc/hostname"
		echo $nom_poste > /etc/hostname
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
	echo "on définit le nom du poste : epnWBib-[type][numéro]"
	fn_type_poste
	fn_num_poste
	nom_poste="epnWBib-"$type_poste$num_poste
	fn_valide_nom_poste
}

fn_nommer_poste

#on fixe les dépôts logiciels
printline %
liste_base="/etc/apt/sources.list.d/official-package-repositories.list"

if [ -f $liste_base ];
then
   echo "Le fichier $list_base existe, on le sauvegarde."
   mv $list_base $liste_base".orig"
   cp $workdir/etc/apt/sources.list.d/official-package-repositories.list /etc/apt/sources.list.d/
else
   echo "File $list_base does not exist."
   cp $workdir/etc/apt/sources.list.d/official-package-repositories.list /etc/apt/sources.list.d/
fi


#mise à jour du système
# apt-get -y répond par l'affirmative aux questions du gestionnaire de paquets
echo "mise à jour du système (apt-get update && apt-get -y dist-upgrade)"
apt-get update
apt-get -y dist-upgrade

# ajout de l'imprimante // l'ajout manuel est plus fiable 
# adresse 192.168.1.100
#cp -r $workdir/etc/cups/pdd/* /etc/cups/pdd/
#cp $workdir/etc/cups/printers.conf /etc/cups/
#/etc/init.d/cups restart

# ajout de la gestion des comptes invités
echo "ajout de l'utilisateur invité" 
# attention pour ce faire on doit changer de gestionnaire de session, de GDM vers LightDM
echo "on doit changer de gestionnaire de session, de GDM vers LightDM"
apt-get install -y lightdm lightdm-gtk-greeter unity-greeter light-themes light-locker gksu leafpad
# copie de la configuration de lightDM
cp -rf $workdir/etc/lightdm /etc/

# on crée un utilisateur "modele" avec le même mot de passe que root
# ce compte sert à définir le compte invité
# le mot de passe est généré avec mkpasswd et utilse crypt(3)
echo "on crée l'utilisateur 'modele' qui sert de config de base pour l'invité son pwd est celui de l'admin"
useradd -U -s /bin/bash -d /home/modele -m -p bMGU00do6JvyU modele

# copie du home de modele
cp -rf $workdir/$userhome/. $userhome/

chmod +x $userhome/Bureau/*

# on crée un lien sybolique vers le home de modele pour l'utilisateur invité
cp -rf $workdir/etc/guest-session /etc/
ln -s $userhome /etc/guest-session/skel 

# 

# active-t-on un répertore persistant ?
fn_donnees_persistantes () {
	printline %
	echo "active-t-on un répertore persistant ? ? (Y/N O/N)"
	read persistant
	case $persistant in
	O|o|Y|y)
		echo "ok ! on crée /var/guest-data et on l'ajoute aux favoris de Gnome/Cinnamon"
		mkdir -m 0777 /var/guest-data
		echo "file:///var/guest-data Sauvegarde" >> $userhome/.config/gtk-3.0/bookmarks
		printline %
		;;
	N|n)
		echo "Pas de données persistantes alors"
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

# installation du lecteur de cartes d'identité électronique
printline %
echo " installation du lecteur de cartes d'identité électronique"
fn_install_eid () {
  dpkg -i $workdir/deb/eid-archive_2017.1_all.deb 
  apt-get update
  apt-get install eid-mw eid-viewer libacr38u
}
fn_install_eid

# installation des codecs multimédia, d'inkscape et scribus du man en français et ajout du protocole ssh
echo "installation des codecs multimédia, d'inkscape, scribus, du man en français, de ssh et des polices m$"
apt-get -y install ubuntu-restricted-extras inkscape scribus ttf-mscorefonts-installer tesseract-ocr tesseract-ocr-fra manpages-fr ssh

# interdire à public d'utiliser ssh (n'autoriser que epn-admin)
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
echo "AllowUsers epn-admin" >> /etc/ssh/sshd_config

service ssh restart

#mise à jour du système
# apt-get -y répond par l'affirmative aux questions du gestionnaire de paquets
printline %
echo "mise à jour du système (apt-get update && apt-get -y dist-upgrade)"
apt-get update
apt-get -y dist-upgrade

printline %
printline %
echo "\nconfiguration terminée pour $nom_poste\n"
printline %
printline %

cp ${LOG_FILE} ${LOG_FILE}${nom_poste}
