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
metamod_file="http://www.metamodsource.net/mmsdrop/1.10/mmsource-1.10.5-git927-linux.tar.gz"
sourcemod_file="http://www.sourcemod.net/smdrop/1.6/sourcemod-1.6.4-git4621-linux.tar.gz"

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
# If Ubuntu || Debian
elif [[ -f /etc/lsb_release || -f /etc/debian_version ]]; then
	if [[ $(uname -m) == *x86_64* ]]; then
		apt-get -y update lib64gcc1
		apt-get -y install lib32gcc1 tar.x86_64
	else
		apt-get -y install lib32gcc1 tar.i686
	fi
else
	printf "Only CentOS, Fedora, Ubuntu, and Debian officially supported\n"
	(exit 1)
fi
if ! id -u $svc_acct; then
	adduser $svc_acct
fi
} &> install.log

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
game_type=
game_mode=
map_group=
map=
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
	Game Mode & Game Type

	(1) Casual
	(2) Competitive
	(3) Arms Race
	(4) Demolition
	(5) Deathmatch
	(q) Quit
	
	Press [Enter] to continue.
	
	------------------------------
	EOF
	while read; do
		if (( "$REPLY" >= "1" )) && (( "$REPLY" <= "2" )); then
			case $REPLY in
			"1")  game_type="0" game_mode="0"	;;
			"2")  game_type="0" game_mode="1"	;;
			"3")  game_type="1" game_mode="0"	;;
			"4")  game_type="1" game_mode="1"	;;
			"5")  game_type="1" game_mode="2"	;;
			esac
			break
		elif (( "$REPLY" == "q" )); then 
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
	(7) Operation Vanguard
	(q) Quit
	
	Press [Enter] to continue.
	
	------------------------------
	EOF
	while read; do
		if (( "$REPLY" >= "1" )) && (( "$REPLY" <= "7" )); then
			case $REPLY in
			"1")  map_group="mg_active"	;;
			"2")  map_group="mg_reserves"	;;
			"3")  map_group="mg_bomb"	;;
			"4")  map_group="mg_hostage"	;;
			"5")  map_group="mg_demolition"	;;
			"6")  map_group="mg_armsrace"	;;
			"7")  map_group="mg_op_op05"	;;
			esac
			break
		elif (( "$REPLY" == "q" )); then 
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
	Map

	(1)  de_dust2    (15) de_train      (29) ar_monastery
	(2)  de_nuke     (16) cs_workout    (30) ar_shoots
	(3)  de_mirage   (17) cs_backalley  (31) ar_lake
	(4)  de_inferno  (18) de_marquis    (32) ar_stmarc
	(5)  de_cbble    (19) de_facade     (33) ar_safehouse
	(6)  de_overpass (20) de_season     (q)  Quit
	(7)  de_cache    (21) de_bazaar
	(8)  de_aztec    (22) de_bank
	(9)  de_dust     (23) de_lake
	(10) de_vertigo  (24) de_safehouse
	(11) cs_office   (25) de_sugarcane
	(12) cs_italy    (26) de_stmarc
	(13) cs_assault  (27) de_shortdust
	(14) cs_militia  (28) ar_baggage
	
	Press [Enter] to continue.
	
	------------------------------
	EOF
	while read; do
		if (( "$REPLY" >= "1" )) && (( "$REPLY" <= "33" )); then
			case $REPLY in
			"1")   map="de_dust2"		;; "2")   map="de_nuke"			;; "3")   map="de_mirage"		;;
			"4")   map="de_inferno"		;; "5")   map="de_cbble"		;; "6")   map="de_overpass"		;;
			"7")   map="de_cache"		;; "8")   map="de_aztec"		;; "9")   map="de_dust"			;;
			"10")  map="de_vertigo"		;; "11")  map="cs_office"		;; "12")  map="cs_italy"		;;
			"13")  map="cs_assault"		;; "14")  map="cs_militia"		;; "15")  map="de_train"		;;
			"16")  map="cs_workout"		;; "17")  map="cs_backalley"		;; "18")  map="de_marquis"		;;
			"19")  map="de_facade"		;; "20")  map="de_season"		;; "21")  map="de_bazaar"		;;
			"22")  map="de_bank"		;; "23")  map="de_lake"			;; "24")  map="de_safehouse"	;;
			"25")  map="de_sugarcane"	;; "26")  map="de_stmarc"		;; "27")  map="de_shortdust"	;;
			"28")  map="ar_baggage"		;; "29")  map="ar_monastery"		;; "30")  map="ar_shoots"		;;
			"31")  map="ar_lake"		;; "32")  map="ar_stmarc"		;; "33")  map="ar_safehouse"	;;
			esac
			break
		elif (( "$REPLY" == "q" )); then 
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
	Tickrate

	(1) 64 Tick
	(2) 128 Tick
	(q) Quit
	
	Press [Enter] to continue.
	
	------------------------------
	EOF
	while read; do
		if [ $REPLY -ge 1 -a $REPLY -le 2 ]; then
			case $REPLY in
			"1")  tickrate="64"				;;
			"2")  tickrate="128"			;;
			esac
			break
		elif [ $REPLY == q ]; then 
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
	
	------------------------------
	EOF
	while read maxplayers; do
		if [[ "$maxplayers" =~ ^[0-9]+$ ]] && [ "$maxplayers" -ge 1 -a "$maxplayers" -le 32 ]; then
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
	
	------------------------------
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
	
	------------------------------
	EOF
	while read -i "27015" -e port; do
		if [[ $port =~ ^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$ ]]; then
			break;
		else
			printf "Not a valid port number"
		fi
	done
	sleep .5
	
	clear
	cat<<-EOF
	============================
	Counter-Strike Server Setup
	============================
	Server Type

	(1) Practice Server
	(2) Regular
	(q) Quit
	
	Press [Enter] to continue.
	
	------------------------------
	EOF
	while read; do
		if [ $REPLY -ge 1 -a $REPLY -le 2 ]; then
			case $REPLY in
			"1")  servercfg=practice.cfg	;;
			"2")  servercfg=server.cfg	;;
			esac
			break
		elif [ $REPLY == q ]; then 
			exit 1
		else
			echo "Invalid Option"
		fi
	done
	sleep .5
	
	break

done

printf "\nGame Type: ${game_type}\n"
printf "Game Mode: ${game_mode}\n"
printf "Map Group: ${map_group}\n"
printf "Map: ${map}\n"
printf "Tickrate: ${tickrate}\n"
printf "Max Players: ${maxplayers}\n"
printf "IP: ${wan_ip}\n"
printf "Port: ${port}\n\n"

if [[ $servercfg == "practice.cfg" ]]; then
	if [[ -a /home/steam/csgo/csgo/cfg/gamemode_competitive.cfg ]]; then
		mv /home/steam/csgo/csgo/cfg/gamemode_competitive.cfg /home/steam/csgo/csgo/cfg/gamemode_competitive.bak
	fi
	./srcds_run -game csgo -usercon -strictportbind +game_mode 1 +game_type 0 +mapgroup ${map_group} +map ${map} -tickrate ${tickrate} -maxplayers_override ${maxplayers} -ip ${ip} -port ${port} +servercfgfile ${servercfg}
elif [[ $servercfg == "server.cfg" ]]; then
	if [[ -a /home/steam/csgo/csgo/cfg/gamemode_competitive.bak ]]; then
		mv /home/steam/csgo/csgo/cfg/gamemode_competitive.bak /home/steam/csgo/csgo/cfg/gamemode_competitive.cfg
	fi
	./srcds_run -game csgo -usercon -strictportbind +game_mode ${game_mode} +game_type ${game_type} +mapgroup ${map_group} +map ${map} -tickrate ${tickrate} -maxplayers_override ${maxplayers} -ip ${ip} -port ${port} +servercfgfile ${servercfg}
fi

EOF

cat <<EOF > /home/$svc_acct/$game_folder/csgo/cfg/practice.cfg

//GAME: Counter-Strike: Source 
//TYPE: Practice Server Config 

//Host and RCON settings
hostname				"${server_name}"
rcon_password				"${rcon_password}"
sv_password				"${server_password}"
sv_rcon_banpenalty			"0"
sv_rcon_maxfailures			"10"
sv_rcon_minfailures			"5"
sv_rcon_minfailuretime			"30"
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
sv_minrate				"7500"
sv_maxrate				"25000"
decalfrequency				"30"
sv_minupdaterate			"100"
sv_maxupdaterate			"101"

//Server logging
log					"off"
sv_logbans				"0"
sv_logecho				"1"
sv_logfile				"1"
sv_log_onefile				"0"

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
hostname				"${server_name}"
rcon_password				"${rcon_password}"
sv_password				"${server_password}"
sv_rcon_banpenalty			"0"
sv_rcon_maxfailures			"10"
sv_rcon_minfailures			"5"
sv_rcon_minfailuretime			"30"

//Bandwidth Rates
sv_minrate				"7500"
sv_maxrate				"25000"
decalfrequency				"30"
sv_minupdaterate			"100"
sv_maxupdaterate			"101"

//Server logging
log					"off"
sv_logbans				"0"
sv_logecho				"1"
sv_logfile				"1"
sv_log_onefile				"0"

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
