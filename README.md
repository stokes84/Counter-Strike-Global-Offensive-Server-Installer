Counter-Strike: Global Offensive Server Installer
================================================

Automated Counter-Strike Global Offensive Server Installer with Metamod and Sourcemod. Taking <a href="https://github.com/dgibbs64" target="_blank">@dgibbs64</a>'s installer a step further automating all tasks and adding a platform for server plugins and web admin front end. 
<br><br>
Docs on Linux Server Manager (base): http://danielgibbs.co.uk/lgsm/csgoserver/
<br><br>
Metamod: https://www.sourcemm.net/
<br>
Metamod Plugins: https://forums.alliedmods.net/forumdisplay.php?f=108
<br><br>
SourceMod: http://www.sourcemod.net/
<br>
SourceMod Plugins: http://www.sourcemod.net/plugins.php?cat=0&mod=21&title=&author=&description=&search=1
<br><br>
CS:GO Web Admin: http://sourceforge.net/projects/csgowebadmin/
<br><br>
Installation
------------
``` Coming Soon ```
Compatibility
-------------
+ CentOS 6/7
+ Ubuntu 12/14
+ Debian 6/7

Usage
-----
Start: ``` csgoserver start ```<br>
Stop: ``` csgoserver stop ```<br>
Restart: ``` csgoserver restart ```<br>
Update: ``` csgoserver update ```<br>
Update + Restart: ``` csgoserver update-restart ```<br>
Validate: ``` csgoserver validate ```<br>
Validate + Restart: ``` csgoserver validate-restart ```<br>
Config Details: ``` csgoserver config ```<br>
Console: ``` csgoserver console ```<br>
Backup: ``` csgoserver backup ```<br>
Test Email Notifications: ``` csgoserver email-test ```<br>
Debug: ``` csgoserver debug ```

Files
-----
Server Config: ``` /home/csgoserver/ ```<br>
Plugins Folder: ``` /home/csgoserver/ ```<br>
Web Admin: ``` /home/csgoserver/ ```

Automations
-----------
Server: Starts @ boot
Updates: Daily @ 5am && restart
Monitor: On always (will restart if no response for 5 sec)


