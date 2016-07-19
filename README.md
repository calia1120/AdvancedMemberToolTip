-------------------------------------------------------------------------------
Advanced Member Tooltip v1.1 6/5/16
Author: Arkadius (@arkadius1 EU), updated by Calia1120
-------------------------------------------------------------------------------
This Add-on is not created by, affiliated with or sponsored by ZeniMax Media
Inc. or its affiliates. The Elder Scrolls� and related logos are registered
trademarks or trademarks of ZeniMax Media Inc. in the United States and/or
other countries.

You can read the full terms at:
https://account.elderscrollsonline.com/add-on-terms

-------------------------------------------------------------------------------
Description
Adds time of membership and guild bank depositions/withdrawals (gold only) to 
the guild roster tooltips. 

This addon adds some information to the standard guild roster tooltips:
- Days since a member joined
- Amount of gold that a member deposited on / withdrawed from the guild bank

When the addon is run for the very first time, it needs to download all 
information from the server first. This needs to be done only one time and may 
take some minutes. NOTE: If you're running other addons, that request guild 
histories (like Shopkeeper or Master Merchant) you might get booted from the 
server because of spam. In that case, I suggest to disable those addons for this 
first scan.

After the initial scan, all further scans are done periodically every 5 minutes 
to keep the information up to date.

* This addon does not have an in game settings menu currently. I am planning 
on adding in on addition to some other features in the future as time permits.

-------------------------------------------------------------------------------
Manual Installation
-------------------------------------------------------------------------------

1. Go to the "Elder Scrolls Online" folder in your Documents.

NA Version
For Windows: C:\Users\<username>\Documents\Elder Scrolls Online\live\
For Mac: ~/Documents/Elder Scrolls Online/live/

EU Version
For Windows: C:\Users\<username>\Documents\Elder Scrolls Online\liveeu\
For Mac: ~/Documents/Elder Scrolls Online/liveeu/

2. You should find an AddOns folder. If you don't, create one.
3. Extract the addon from the downloaded zip file to the AddOns folder.
4. Log into the game, and in the character creation screen, you'll find
   the addons menu. Enable your addons from there.

-------------------------------------------------------------------------------
Changelog
-------------------------------------------------------------------------------
v1.1 (6/6/16)
	* Goofed the README file, my bad. Fixed!
-------------------------------------------------------------------------------
v1.0 (6/5/16)
	* Updated API for Dark Brotherhood patch, added language localizations for 
	FR, corrected some German localizations as well.

-------------------------------------------------------------------------------
v0.1.2 (4/23/15)
	- Fixed a bug where AMT would display too high numbers for memberships
	
-------------------------------------------------------------------------------
v0.1.1 (4/17/15)
	- Fixed a bug that caused a LUA error when requesting a tooltip of a guild 
	member that wasn't scanned yet
	- Added some text output during the initial scan to let the user know about 
	the progress
	
-------------------------------------------------------------------------------
v0.1.0 (4/15/15)
	- Initial release
