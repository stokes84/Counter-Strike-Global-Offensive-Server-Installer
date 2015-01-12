<h1 align='center'>Counter-Strike: Global Offensive Server Installer</h1>

Automated Counter-Strike Global Offensive Server Installer with Metamod and Sourcemod.
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

Dependencies
------------
###CentOS / Fedora - Prerequisites
####64bit
```yum -y update glibc.x86_64 libstdc++.x86_64```
<br>
```yum -y install glibc.i686 libstdc++.i686```
####32bit
```yum -y install glibc libstdc++```
###Ubuntu / Debian - Prerequisites
####64bit
```apt-get -y update lib64gcc1```
<br>
```apt-get -y install lib32gcc1```
####32bit
```apt-get -y install lib32gcc1```

<br><br>

Install
-------
```adduser steam```
<br>
``su steam```
<br>
```cd /home/steam```
<br>
```wget https://raw.githubusercontent.com/stokes84/Counter-Strike-Global-Offensive-Server-Installer/master/install.sh```
<br>
```bash install.sh```

<br><br>

Usage
-----
```./srcds_run -game csgo```

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
