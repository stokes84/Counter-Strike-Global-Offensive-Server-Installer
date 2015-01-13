<h2 align='center'>Counter-Strike: Global Offensive Server Installer</h2>

<p align='center'>Automated Counter-Strike Global Offensive Server Installer with Metamod and Sourcemod.</p>
<br><br>
Metamod: https://www.sourcemm.net/
<br>
Metamod Plugins: https://forums.alliedmods.net/forumdisplay.php?f=108
<br><br>
SourceMod: http://www.sourcemod.net/
<br>
SourceMod Plugins: http://www.sourcemod.net/plugins.php?cat=0&mod=21&title=&author=&description=&search=1

<br><br>

Compatibility
-------------
+ CentOS 6/7
+ Fedora 19/20
+ Ubuntu 12/14
+ Debian 6/7

<br><br>

Install
-------
```
su root
```
```
wget https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/install.sh
```
```
bash install.sh
```

<br><br>

Usage
-----
```
su steam
```
```
cd /home/steam/csgo
```
```
./srcds_run -game csgo
```

<br><br>

Command Line Options
--------------------
+ -usercon (enable rcon)
+ -strictportbind (prevent binding to next available port)
+ -ip
+ -port
+ +clientport
+ +tv_port
+ -tickrate
+ +map
+ +servercfgfile
+ -maxplayers
+ +mapgroup
+ +game_mode
+ +game_type
+ +host_workshop_collection 
+ +workshop_start_map 
+ -authkey
