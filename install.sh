#!/bin/bash
# Last Updated - 3/16/15
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
steam_file="http://media.steampowered.com/installer/steamcmd_linux.tar.gz"
metamod_file="http://www.gsptalk.com/mirror/sourcemod/mmsource-1.10.4-linux.tar.gz"
sourcemod_file="http://www.gsptalk.com/mirror/sourcemod/sourcemod-1.7.0-linux.tar.gz"

# Hide Cursor & Clear Screen
tput civis
trap 'tput cnorm' EXIT
tput clear

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
            # Calculate the column where spinner and status msg will be displayed
            let column=$(tput cols)-${#2}
            # Display message and position the cursor in $column column
            printf "${2}"
            printf "%${column}s"

            # Start spinner
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
                # Spinner isn't running
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
		error_title="${bold}Check Error Log${normal}"
		printf "%*s\n" $(((${#error_title}+$(tput cols))/2)) "$error_title"
		eval printf %.0s- '{1..'"${COLUMNS:-$(tput cols)}"\}; echo
		tail -2 install.log
		printf "\n"
		exit 1
            fi
            ;;
        *)
            # Invalid argument
            exit 1
            ;;
    esac
}

function start_spinner {
    # $1 : Msg to display
    _spinner "start" "${1}" &
    # Set global spinner pid
    _sp_pid=$!
    disown
}

function stop_spinner {
    # $1 : Command exit status
    _spinner "stop" $1 $_sp_pid
    unset _sp_pid
}

# Remove previous install log
if [[ -f "install.log" ]]; then
	rm -f install.log
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
		yum -y install glibc.i686 libstdc++.i686 tar.x86_64
	else
		yum install -y glibc libstdc++ tar.i686
	fi
	if ! id -u $svc_acct; then
		adduser $svc_acct
		echo 'alias csgo="cd /home/steam/csgo; ./launch.sh"' >> /home/steam/.bashrc
	fi
# If Ubuntu || Debian
elif [[ -f /etc/lsb_release || -f /etc/debian_version ]]; then
	if [[ $(uname -m) == *x86_64* ]]; then
		apt-get -y update lib64gcc1
		apt-get -y install lib32gcc1 tar
	else
		apt-get -y install lib32gcc1 tar
	fi
	if ! id -u $svc_acct; then
		adduser --disabled-password --gecos "" $svc_acct
		echo 'alias csgo="cd /home/steam/csgo; ./launch.sh"' >> /home/steam/.bashrc
	fi
else
	printf "Only CentOS, Fedora, Ubuntu, and Debian officially supported\n"
	(exit 1)
fi
} &> install.log

stop_spinner $?

start_spinner "${bold}Installing SteamCMD${normal}"

{
cd /home/$svc_acct
mkdir $steamcmd_folder
cd $steamcmd_folder
wget -4 --timeout=5 --tries=3 ${steam_file}
tar -xvzf steamcmd_linux.tar.gz
rm -f steamcmd_linux.tar.gz
./steamcmd.sh +login anonymous +force_install_dir /home/$svc_acct +quit
} &>> install.log

stop_spinner $?

start_spinner "${bold}Installing Counter-Strike: Global Offensive${normal}"

{
./steamcmd.sh +login anonymous +force_install_dir /home/$svc_acct/$game_folder +app_update 740 validate +quit
} &>> install.log

stop_spinner $?

start_spinner "${bold}Installing MetaMod${normal}"

{
cd /home/$svc_acct/$game_folder/csgo
wget -4 ${metamod_file}
tar xfz mmsource*
rm -f mmsource*
sed -i 's|addons/metamod/bin/server|../csgo/addons/metamod/bin/server|g' addons/metamod.vdf
} &>> install.log

stop_spinner $?

start_spinner "${bold}Installing SourceMod${normal}"

{
# Install SourceMod
wget -4 ${sourcemod_file} 
tar xfz sourcemod*
rm -f sourcemod*
} &>> install.log

stop_spinner $?

start_spinner "${bold}Installing Plugins${normal}"

{
# Download Naid Tails Plugin For Practice Mode @ https://forums.alliedmods.net/showthread.php?t=240668
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/nadetails/NadeTails.smx -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/plugins/NadeTails.disabled

# Download Retakes Plugin As Server Option @ https://forums.alliedmods.net/showthread.php?t=251829
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/retakes/addons/sourcemod/plugins/retakes.smx -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/plugins/retakes.disabled
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/retakes/addons/sourcemod/scripting/retakes.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/retakes.sp
sed -i '$ d' /home/$svc_acct/$game_folder/csgo/addons/sourcemod/configs/databases.cfg
cat <<'EOF' >> /home/$svc_acct/$game_folder/csgo/addons/sourcemod/configs/databases.cfg
    "retakes"
	{
        "driver"            "sqlite"
        "host"              "localhost"
        "database"          "retakes-sqlite"
        "user"              "root"
        "pass"              ""
    }
}
EOF
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/retakes/cfg/retakes.cfg -O /home/$svc_acct/$game_folder/csgo/cfg/sourcemod/retakes.cfg
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/retakes/cfg/retakes_live.cfg -O /home/$svc_acct/$game_folder/csgo/cfg/sourcemod/retakes_live.cfg
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/retakes/cfg/retakes_warmup.cfg -O /home/$svc_acct/$game_folder/csgo/cfg/sourcemod/retakes_warmup.cfg
mkdir /home/$svc_acct/$game_folder/csgo/addons/sourcemod/data/sqlite
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/retakes/addons/sourcemod/data/sqlite/retakes-sqlite.sq3 -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/data/sqlite/retakes-sqlite.sq3

# Download Multi 1v1 Plugin https://forums.alliedmods.net/showthread.php?t=241056
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/configs/multi1v1_weapons.cfg -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/configs/multi1v1_weapons.cfg
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/plugins/multi1v1.smx -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/plugins/multi1v1.disabled
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/plugins/disabled/multi1v1_flashbangs.smx -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/plugins/disabled/multi1v1_flashbangs.smx
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/plugins/disabled/multi1v1_kniferounds.smx -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/plugins/disabled/multi1v1_kniferounds.smx
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/include/multi1v1.inc -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/include/multi1v1.inc
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/include/queue.inc -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/include/queue.inc
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/include/updater.inc -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/include/updater.inc
mkdir /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/multi1v1/generic.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1/generic.sp
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/multi1v1/natives.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1/natives.sp
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/multi1v1/radiocommands.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1/radiocommands.sp
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/multi1v1/roundtypes.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1/roundtypes.sp
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/multi1v1/spawns.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1/spawns.sp
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/multi1v1/stats.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1/stats.sp
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/multi1v1/version.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1/version.sp
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/multi1v1/weaponlogic.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1/weaponlogic.sp
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/multi1v1.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1.sp
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/multi1v1_flashbangs.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1_flashbangs.sp
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/multi1v1_kniferounds.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1_kniferounds.sp
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/scripting/multi1v1_online_stats_viewer.sp -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/scripting/multi1v1_online_stats_viewer.sp
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/translations/chi/multi1v1.phrases.txt -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/translations/chi/multi1v1.phrases.txt
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/translations/de/multi1v1.phrases.txt -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/translations/de/multi1v1.phrases.txt
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/translations/fr/multi1v1.phrases -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/translations/fr/multi1v1.phrases
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/translations/pl/multi1v1.phrases.txt -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/translations/pl/multi1v1.phrases.txt
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/translations/pt_p/multi1v1.phrases.txt -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/translations/pt_p/multi1v1.phrases.txt
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/translations/sv/multi1v1.phrases.txt -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/translations/sv/multi1v1.phrases.txt
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/translations/multi1v1.phrases.txt -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/translations/multi1v1.phrases.txt
mkdir /home/$svc_acct/$game_folder/csgo/cfg/sourcemod/multi1v1
wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/cfg/sourcemod/multi1v1/game_cvars.cfg -O /home/$svc_acct/$game_folder/csgo/cfg/sourcemod/multi1v1/game_cvars.cfg
### Disabled online stats viewer plugin due to manual DB creation needed
### DB creation instructions @ https://github.com/splewis/csgo-multi-1v1/blob/v1.0.0/README.md
### Alter DB connection info and use commands below then create DB
#wget --no-check-certificate https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/1v1/addons/sourcemod/plugins/disabled/multi1v1_online_stats_viewer.smx -O /home/$svc_acct/$game_folder/csgo/addons/sourcemod/plugins/disabled/multi1v1_online_stats_viewer.smx
#sed -i '$ d' /home/$svc_acct/$game_folder/csgo/addons/sourcemod/configs/databases.cfg
#cat <<'EOF' >> /home/$svc_acct/$game_folder/csgo/addons/sourcemod/configs/databases.cfg
#	"multi1v1"
#	{
#		"driver"            "mysql"
#		"host"              "123.123.123.123"   // localhost works too
#		"database"          "game_servers_database"
#		"user"              "mymulti1v1server"
#		"pass"              "strongpassword"
#		"timeout"           "10"
#		"port"          "3306"  // whatever port MySQL is set up on, 3306 is default
#	}
#}
#EOF
} &>> install.log

stop_spinner $?

tput sc; tput cnorm;
tput rc; tput el
read -e -p "${bold}Server Name: ${normal}" server_name
tput rc; tput el
read -e -p "${bold}RCON Password: ${normal}" rcon_password
tput rc; tput el
read -e -p "${bold}Server Password (blank = not required): ${normal}" server_password
tput rc; tput el; tput civis

start_spinner "${bold}Creating CSGO Launcher${normal}"

{
cat <<'EOF' > /home/$svc_acct/$game_folder/launch.sh
#!/bin/bash
servercfg=
server=
workshop=
authkey=
game_type=
game_mode=
map=
map_group=
tickrate=
maxplayers=
wan_ip=$(wget -qO- http://ipecho.net/plain ; echo)
port=

while :
do 

	clear
	cat<<-EOF
	============================
	Counter-Strike Server Setup
	============================
	Server Type

	(1) Standard
	(2) Practice Mode
	(3) Retakes Server
	(4) 1v1 Arena Server
	(q) Quit
	
	Press [Enter] to continue.
	
	-----------------------------
	EOF
	while read; do
		if (( "$REPLY" >= "1" )) && (( "$REPLY" <= "4" )); then
			case $REPLY in
			"1")  servercfg="server.cfg" 	server=standard	;;
			"2")  servercfg="practice.cfg" 	server=practice	;;
			"3")  servercfg="server.cfg" 	server=retakes	;;
			"4")  servercfg="server.cfg" 	server=1v1		workshop=true;;
			esac
			break
		elif [[ "$REPLY" == "q" ]]; then 
			exit 1
		else
			echo "Invalid Option"
		fi
	done
	sleep .5
	
	if [[ $workshop == "true" ]]; then
	
		clear
		cat<<-EOF
		============================
		Counter-Strike Server Setup
		============================
		Workshop Auth Key

		To Generate Key: http://steamcommunity.com/dev/apikey
		
		(q) Quit

		Press [Enter] to continue.

		-----------------------------
		EOF
		while read -i ${authkey} -e authkey; do
			if [[ "$authkey" == "q" ]]; then
				exit 1
			elif ! [[ "$authkey" =~ [^a-zA-Z0-9] ]] && [[ -n "$authkey" ]]; then 
				sed -i '0,/authkey\=/s//authkey\=\${authkey}/' launch.sh
				break
			else
				echo "Invalid Option"
				authkey=
			fi
		done
		sleep .5
	
	else
	
		if [[ $server == "standard" ]]; then
		
			clear
			cat<<-EOF
			============================
			Counter-Strike Server Setup
			============================
			Game Mode & Game Type

			(1) Casual
			(2) Competitive
			(3) Arms Race
			(4) Demolition
			(5) Deathmatch
			(q) Quit
		
			Press [Enter] to continue.
		
			-----------------------------
			EOF
			while read; do
				if (( "$REPLY" >= "1" )) && (( "$REPLY" <= "5" )); then
					case $REPLY in
					"1")  game_type="0" game_mode="0"	;;
					"2")  game_type="0" game_mode="1"	;;
					"3")  game_type="1" game_mode="0"	;;
					"4")  game_type="1" game_mode="1"	;;
					"5")  game_type="1" game_mode="2"	;;
					esac
					break
				elif [[ "$REPLY" == "q" ]]; then 
					exit 1
				else
					echo "Invalid Option"
				fi
			done
			sleep .5
				
		fi

		
		clear
		cat<<-EOF
		============================
		Counter-Strike Server Setup
		============================
		Map

		(1)  de_dust2     (2)  de_nuke      (3)  de_mirage	
		(4)  de_inferno   (5)  de_cbble     (6)  de_overpass
		(7)  de_cache     (8)  de_aztec     (9)  de_dust
		(10) de_vertigo   (11) cs_office    (12) cs_italy
		(13) cs_assault   (14) cs_militia   (15) de_train
		(16) de_bank      (17) de_lake      (18) de_safehouse
		(19) de_sugarcane (20) de_stmarc    (21) de_shortdust
		(22) ar_baggage   (23) ar_monastery (24) ar_shoots
		(25) ar_lake      (26) ar_stmarc    (27) ar_safehouse
		(q)  Quit
		
		Press [Enter] to continue.
		
		-----------------------------
		EOF
		while read; do
			if (( "$REPLY" >= "1" )) && (( "$REPLY" <= "27" )); then
				case $REPLY in
				"1")   map="de_dust2"		;; "2")   map="de_nuke"			;; "3")   map="de_mirage"		;;
				"4")   map="de_inferno"		;; "5")   map="de_cbble"		;; "6")   map="de_overpass"		;;
				"7")   map="de_cache"		;; "8")   map="de_aztec"		;; "9")   map="de_dust"			;;
				"10")  map="de_vertigo"		;; "11")  map="cs_office"		;; "12")  map="cs_italy"		;;
				"13")  map="cs_assault"		;; "14")  map="cs_militia"		;; "15")  map="de_train"		;;
				"16")  map="de_bank"		;; "17")  map="de_lake"			;; "18")  map="de_safehouse"		;;
				"19")  map="de_sugarcane"	;; "20")  map="de_stmarc"		;; "21")  map="de_shortdust"		;;
				"22")  map="ar_baggage"		;; "23")  map="ar_monastery"	;; "24")  map="ar_shoots"		;;
				"25")  map="ar_lake"		;; "26")  map="ar_stmarc"		;; "27")  map="ar_safehouse"		;;
				esac
				break
			elif [[ "$REPLY" == "q" ]]; then 
				exit 1
			else
				echo "Invalid Option"
			fi
		done
		sleep .5
		
		
		clear
		cat<<-EOF
		============================
		Counter-Strike Server Setup
		============================
		Map Group

		(1) Active
		(2) Reserves
		(3) Bomb
		(4) Hostage
		(5) Demolition
		(6) Arms Race
		(6) Deathmatch
		(q) Quit
		
		Press [Enter] to continue.
		
		-----------------------------
		EOF
		while read; do
			if (( "$REPLY" >= "1" )) && (( "$REPLY" <= "6" )); then
				case $REPLY in
				"1")  map_group="mg_active"	;;
				"2")  map_group="mg_reserves"	;;
				"3")  map_group="mg_bomb"	;;
				"4")  map_group="mg_hostage"	;;
				"5")  map_group="mg_demolition"	;;
				"6")  map_group="mg_armsrace"	;;
				esac
				break
			elif [[ "$REPLY" == "q" ]]; then 
				exit 1
			else
				echo "Invalid Option"
			fi
		done
		sleep .5
	
	fi
	
	
	clear
	cat<<-EOF
	============================
	Counter-Strike Server Setup
	============================
	Tickrate

	(1) 64 Tick
	(2) 128 Tick
	(q) Quit
	
	Press [Enter] to continue.
	
	-----------------------------
	EOF
	while read; do
		if (( "$REPLY" >= "1" )) && (( "$REPLY" <= "2" )); then
			case $REPLY in
			"1")  tickrate="64"				;;
			"2")  tickrate="128"			;;
			esac
			break
		elif [[ "$REPLY" == "q" ]]; then 
			exit 1
		else
			echo "Invalid Option"
		fi
	done
	sleep .5
	
	
	clear
	cat<<-EOF
	============================
	Counter-Strike Server Setup
	============================
	Max Players

	Minimum: 1
	Maximum: 32
	
	Press [Enter] to continue.
	
	-----------------------------
	EOF
	while read maxplayers; do
		if (( "$maxplayers" >= "1" )) && (( "$maxplayers" <= "32" )); then
			break
		else
			echo "Invalid Option"
		fi
	done
	sleep .5
	
	
	clear
	cat<<-EOF
	============================
	Counter-Strike Server Setup
	============================
	IP Address

	Default: 0.0.0.0
	Your IP: ${wan_ip}
	
	Press [Enter] to continue.
	
	-----------------------------
	EOF
	while read -i ${wan_ip} -e wan_ip; do
		if [[ $wan_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
			break
		else
			echo "Not a valid IP Address"
		fi
	done
	sleep .5
	
	
	clear
	cat<<-EOF
	============================
	Counter-Strike Server Setup
	============================
	Server Listen Port

	Default: 27015
	
	Press [Enter] to continue.
	
	-----------------------------
	EOF
	while read -i "27015" -e port; do
		if [[ $port =~ ^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$ ]]; then
			break;
		else
			printf "Not a valid port number"
		fi
	done
	sleep .5
	
	break

done

# Reset Default Comp Config
if [[ -a /home/steam/csgo/csgo/cfg/gamemode_competitive.cfg ]]; then
	mv /home/steam/csgo/csgo/cfg/gamemode_competitive.cfg /home/steam/csgo/csgo/cfg/gamemode_competitive.bak
fi

# Reset Retakes
if [[ -a /home/steam/csgo/csgo/addons/sourcemod/plugins/retakes.smx  ]]; then
	mv /home/steam/csgo/csgo/addons/sourcemod/plugins/retakes.smx /home/steam/csgo/csgo/addons/sourcemod/plugins/retakes.disabled
fi

# Reset Nade Tails
if [[ -a /home/steam/csgo/csgo/addons/sourcemod/plugins/NadeTails.smx ]]; then
	mv /home/steam/csgo/csgo/addons/sourcemod/plugins/NadeTails.smx /home/steam/csgo/csgo/addons/sourcemod/plugins/NadeTails.disabled
fi

# Reset Multi 1v1 Plugin
if [[ -a /home/steam/csgo/csgo/addons/sourcemod/plugins/multi1v1.smx ]]; then
	mv /home/steam/csgo/csgo/addons/sourcemod/plugins/multi1v1.smx /home/steam/csgo/csgo/addons/sourcemod/plugins/multi1v1.disabled
fi

if [[ $server == "standard" ]]; then
	
	# Enable Default Comp Mode Config For Standard Servers
	if [[ -a /home/steam/csgo/csgo/cfg/gamemode_competitive.bak ]]; then
		mv /home/steam/csgo/csgo/cfg/gamemode_competitive.bak /home/steam/csgo/csgo/cfg/gamemode_competitive.cfg
	fi
	
	./srcds_run -game csgo -usercon -strictportbind +game_mode ${game_mode} +game_type ${game_type} +mapgroup ${map_group} +map ${map} -tickrate ${tickrate} -maxplayers_override ${maxplayers} -ip ${ip} -port ${port} +servercfgfile ${servercfg}
	
fi

if [[ $server == "practice" ]]; then

	# Enable Nade Tails Plugin
	if [[ -a /home/steam/csgo/csgo/addons/sourcemod/plugins/NadeTails.disabled ]]; then
		mv /home/steam/csgo/csgo/addons/sourcemod/plugins/NadeTails.disabled /home/steam/csgo/csgo/addons/sourcemod/plugins/NadeTails.smx
	fi
	
	./srcds_run -game csgo -usercon -strictportbind +game_mode 1 +game_type 0 +mapgroup ${map_group} +map ${map} -tickrate ${tickrate} -maxplayers_override ${maxplayers} -ip ${ip} -port ${port} +servercfgfile ${servercfg}
	
fi
	
if [[ $server == "retakes" ]]; then

	# Enable Retakes Plugin
	if [[ -a /home/steam/csgo/csgo/addons/sourcemod/plugins/retakes.disabled  ]]; then
		mv /home/steam/csgo/csgo/addons/sourcemod/plugins/retakes.disabled /home/steam/csgo/csgo/addons/sourcemod/plugins/retakes.smx
	fi
	
	if [[ -a /home/steam/csgo/csgo/cfg/gamemode_competitive.bak ]]; then
		mv /home/steam/csgo/csgo/cfg/gamemode_competitive.bak /home/steam/csgo/csgo/cfg/gamemode_competitive.cfg
	fi
	
	./srcds_run -game csgo -usercon -strictportbind +game_mode 1 +game_type 0 +mapgroup ${map_group} +map ${map} -tickrate ${tickrate} -maxplayers_override ${maxplayers} -ip ${ip} -port ${port} +servercfgfile ${servercfg}
	
fi

if [[ $server == "1v1" ]]; then

	# Enable Multi 1v1 Plugin
	if [[ -a /home/steam/csgo/csgo/addons/sourcemod/plugins/multi1v1.disabled  ]]; then
		mv /home/steam/csgo/csgo/addons/sourcemod/plugins/multi1v1.disabled /home/steam/csgo/csgo/addons/sourcemod/plugins/multi1v1.smx
	fi
	
	./srcds_run -game csgo -usercon -strictportbind -tickrate ${tickrate} -maxplayers_override ${maxplayers} -ip ${ip} -port ${port} +servercfgfile ${servercfg} -authkey ${authkey} +host_workshop_collection 279177557 +workshop_start_map 280544066
	
fi
EOF

cat <<EOF > /home/$svc_acct/$game_folder/csgo/cfg/practice.cfg

//GAME: Counter-Strike: Source 
//TYPE: Practice Server Config 

//Host and RCON settings
hostname								"${server_name}"
rcon_password							"${rcon_password}"
sv_password								"${server_password}"
sv_rcon_banpenalty						"0"
sv_rcon_maxfailures						"10"
sv_rcon_minfailures						"5"
sv_rcon_minfailuretime					"30"
sv_cheats                               "1"
bot_quota                               "2"
bot_dont_shoot                          "1"
bot_chatter                             "off"
bot_join_after_player                   "0"
cl_showpos                              "1"
sv_showimpacts                          "1"
mp_limitteams                           "0"
mp_autoteambalance                      "0"
bot_stop                                "1"
mp_freezetime                           "0"
mp_buy_anywhere                         "1"
mp_roundtime_hostage                    "60"
mp_roundtime_defuse                     "60"
mp_startmoney                           "16000"
mp_afterroundmoney                      "16000"
mp_buytime                              "999"
mp_maxrounds                            "1000"
mp_timelimit                            "0"
mp_freezetime                           "0"
sv_alltalk                              "1"
sv_deadtalk                             "1"
sv_infinite_ammo                        "1"
mp_autokick                             "0"
sv_kick_ban_duration                    "0"    
ammo_grenade_limit_flashbang            "2"
ammo_grenade_limit_total                "5"
sv_grenade_trajectory                   "1"
sv_grenade_trajectory_time              "1"
mp_radar_showall                        "1"
mp_respawn_on_death_t                   "1"
mp_respawn_on_death_ct                  "1"
mp_ct_default_melee                     "weapon_knife_bayonet"
mp_ct_default_grenades                  "weapon_hegrenade weapon_flashbang weapon_smokegrenade weapon_incgrenade"
mp_ct_default_secondary                 "weapon_p250"
mp_ct_default_primary                   "weapon_m4a1_silencer"
mp_t_default_melee                      "weapon_knife_bayonet"
mp_t_default_grenades                   "weapon_hegrenade weapon_flashbang weapon_smokegrenade weapon_molotov"
mp_t_default_secondary                  "weapon_p250"
mp_t_default_primary                    "weapon_ak47"
mp_warmup_end

//Bandwidth Rates
sv_minrate					"7500"
sv_maxrate					"25000"
decalfrequency				"30"
sv_minupdaterate			"100"
sv_maxupdaterate			"101"

//Server logging
log						"off"
sv_logbans				"0"
sv_logecho				"1"
sv_logfile				"1"
sv_log_onefile			"0"

//Operation
sv_lan					"0"
sv_region				"1"
sv_contact				""

//Non selectable
exec banned_user.cfg
exec banned_ip.cfg
writeid
writeip

EOF

cat <<EOF > /home/$svc_acct/$game_folder/csgo/cfg/server.cfg

//GAME: Counter-Strike: Source 
//TYPE: Regular Server Config 

//Host and RCON settings
hostname					"${server_name}"
rcon_password				"${rcon_password}"
sv_password					"${server_password}"
sv_rcon_banpenalty			"0"
sv_rcon_maxfailures			"10"
sv_rcon_minfailures			"5"
sv_rcon_minfailuretime		"30"

//Bandwidth Rates
sv_minrate					"7500"
sv_maxrate					"25000"
decalfrequency				"30"
sv_minupdaterate			"100"
sv_maxupdaterate			"101"

//Server logging
log						"off"
sv_logbans				"0"
sv_logecho				"1"
sv_logfile				"1"
sv_log_onefile			"0"

//Operation
sv_lan					"0"
sv_region				"1"
sv_contact				""

//Non selectable
exec banned_user.cfg
exec banned_ip.cfg
writeid
writeip

EOF

}

stop_spinner $?

start_spinner "${bold}Performing Post-Install Tasks${normal}"

{
# Change ownership of everything to our service account
chown -R $svc_acct:$svc_acct /home/$svc_acct
chmod +x /home/$svc_acct/$game_folder/launch.sh
} &> install.log

stop_spinner $?

printf "${bold}Install Complete!${normal}\n"
tput cnorm
