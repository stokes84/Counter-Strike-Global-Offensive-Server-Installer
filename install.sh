#!/bin/bash
# Last Updated - 1/10/15
# Chris Stokes - https://github.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer
################################################
# CentOS / Fedora -- Step 1		       #
# --- 32bit ---				       #
# yum -y install glibc libstdc++	       #
#					       #
# --- 64bit ---				       #
# yum -y update glibc.x86_64 libstdc++.x86_64  #
# yum -y install glibc.i686 libstdc++.i686     #
#					       #
################################################
# Ubuntu / Debian -- Step 1		       #
# --- 32bit ---				       #
# apt-get -y install lib32gcc1		       #
#					       #
# --- 64bit ---				       #
# apt-get -y update lib64gcc1 		       #
# apt-get -y install lib32gcc1		       #
#					       #
#######################################################################################################################
# All Distro's -- Step 2											      #
# adduser steam													      #
# cd /home/steam												      #
# su steam													      #
# wget https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/install.sh  #
# bash install.sh												      #
#######################################################################################################################

# Install Variables
# Check required versions for currrent CSGO build (may need snapshot) https://wiki.alliedmods.net/Required_Versions_(SourceMod)
# MetaMod Downloads: https://www.sourcemm.net/downloads
# SourceMod Downloads: http://www.sourcemod.net/downloads.php
svc_acct="steam"
steamcmd_folder="steamcmd"
game_folder="csgo"
install_log="$( cd "$( dirname "$0" )" && pwd )/install.log"
steam_file="http://media.steampowered.com/installer/steamcmd_linux.tar.gz"
metamod_file="http://www.metamodsource.net/mmsdrop/1.10/mmsource-1.10.5-git927-linux.tar.gz"
sourcemod_file="http://www.sourcemod.net/smdrop/1.6/sourcemod-1.6.4-git4621-linux.tar.gz"

# Styles
bold=`tput bold`
normal=`tput sgr0`
clear=`tput el`
red=`tput setaf 1; tput bold`
green=`tput setaf 2; tput bold`

# Progress spinner function
function _spinner() {
    # 		$1 start/stop
    # on start: $2 display message
    # on stop : $2 process exit status
    #           $3 spinner function pid (supplied from stop_spinner)

    local on_success="SUCCESS"
    local on_fail="FAIL"

    case $1 in
        start)
            # calculate the column where spinner and status msg will be displayed
            let column=$(tput cols)-${#2}-20
            # display message and position the cursor in $column column
            printf "${2}"
            printf "%${column}s"

            # start spinner
            i=1
            sp='\|/-'
            delay=0.15

            while :
            do
                printf "\b${sp:i++%${#sp}:1}"
                sleep $delay
            done
            ;;
        stop)
            if [[ -z ${3} ]]; then
                printf "spinner is not running.."
                exit 1
            fi

            kill $3 > /dev/null 2>&1

            # inform the user uppon success or failure
            if [[ $2 -eq 0 ]]; then
                printf "\b[${green}${on_success}${normal}]\n"
                sleep 1
            else
                printf "\b[${red}${on_fail}${normal}]\n\n"
		eval printf %.0s- '{1..'"${COLUMNS:-$(tput cols)}"\}; echo
		install_log_title="${bold}Check Error Log (${install_log})${normal}"
		printf "%*s\n" $(((${#install_log_title}+$(tput cols))/2)) "$install_log_title"
		eval printf %.0s- '{1..'"${COLUMNS:-$(tput cols)}"\}; echo
		tail -2 ${install_log}
		printf "\n"
		exit 1
            fi
            ;;
        *)
            printf "invalid argument, try {start/stop}"
            exit 1
            ;;
    esac
}

function start_spinner {
    # $1 : msg to display
    _spinner "start" "${1}" &
    # set global spinner pid
    _sp_pid=$!
    disown
}

function stop_spinner {
    # $1 : command exit status
    _spinner "stop" $1 $_sp_pid
    unset _sp_pid
}

# Remove previous install log
if [[ -f $install_log ]]; then
	rm -f $install_log
fi

start_spinner "${bold}Performing Pre-Install Tasks${normal}"

{
if [[ $(whoami) != "root" ]]; then
	printf "Please su root before running this installer\n"
	(exit 1)
fi
# If CentOS || Fedora
if [[ -f /etc/redhat-release ]]; then
	if [[ $(uname -m) == *x86_64* ]]; then
		yum -y update glibc.x86_64 libstdc++.x86_64
		yum -y install glibc.i686 libstdc++.i686
	else
		yum install -y glibc libstdc++
	fi
# If Ubuntu || Debian
elif [[ -f /etc/lsb_release || -f /etc/debian_version ]]; then
	if [[ $(uname -m) == *x86_64* ]]; then
		apt-get -y update lib64gcc1
		apt-get -y install lib32gcc1
	else
		apt-get -y install lib32gcc1
	fi
else
	printf "Only CentOS, Fedora, Ubuntu, and Debian officially supported\n"
	(exit 1)
fi
if ! id -u $svc_acct; then
	adduser $svc_acct
fi
} &> ${install_log}

stop_spinner $?

start_spinner "${bold}Installing SteamCMD${normal}"

{
cd /home/$svc_acct
mkdir $steamcmd_folder
cd $steamcmd_folder
wget -4 ${steam_file}
tar -xvzf steamcmd_linux.tar.gz
rm -f steamcmd_linux.tar.gz
./steamcmd.sh +login anonymous +force_install_dir /home/$svc_acct +quit
} &>> ${install_log}

stop_spinner $?

start_spinner "${bold}Installing Counter-Strike: Global Offensive${normal}"

{
./steamcmd.sh +login anonymous +force_install_dir /home/$svc_acct/$game_folder +app_update 740 validate +quit
} &>> ${install_log}

stop_spinner $?

start_spinner "${bold}Installing MetaMod${normal}"

{
cd /home/$svc_acct/$game_folder/csgo
wget -4 ${metamod_file}
tar xfz mmsource*
rm mmsource*
sed -i 's|addons/metamod/bin/server|../csgo/addons/metamod/bin/server|g' addons/metamod.vdf
} &>> ${install_log}

stop_spinner $?

start_spinner "${bold}Installing SourceMod${normal}"

{
# Install SourceMod
wget -4 ${sourcemod_file} 
tar xfz sourcemod*
rm sourcemod*
} &>> ${install_log}

stop_spinner $?

start_spinner "${bold}Finalizing Install${normal}"

{
# Change ownership of everything to our service account and clean yourself up
chown -R $svc_acct:$svc_acct /home/$svc_acct
rm -f install.sh
rm -f ${install_log}
} &> ${install_log}

stop_spinner $?

printf "${bold}Install Complete!${normal}\n"
