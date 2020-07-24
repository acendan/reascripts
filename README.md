# Aaron Cendan's ReaScripts for [REAPER](https://reaper.fm)
These scripts were written to add additional functionality to the digital audio workstation REAPER. As a sound designer and programmer with a concentration on audio for games, most of these scripts are tailored specifically towards a game audio workflow. If you would like to read more about the development of these scripts or some of the other projects I have worked on in the past, feel free to check out [my website!](https://www.aaroncendan.me/)

**All of the scripts in this repository can be imported directly in Reaper by using the [ReaPack REAPER extension](https://reapack.com/), the free scripts/packages download manager made by cfillion. I strongly recommend setting up ReaPack to install and use these scripts.**

## ReaTeams download instructions
Some of the scripts are included as part of the [ReaTeam Scripts Repository](https://github.com/ReaTeam/ReaScripts). They are included by default with ReaPack, you can simply install ReaPack and synchronize packages by going to the Extensions menu > ReaPack, and clicking "Synchronize Packages".

### Scripts included with ReaTeams
- acendan_Find and Replace in Region Names.lua
- acendan_Find and Replace in Marker Names.lua
- acendan_Set subprojects in selected items to custom color slot.lua (Installs 8 actions - first 8 color slots)
- acendan_Set subprojects in selected items to color.lua
- acendan_Set subprojects in selected items to random colors.lua
- acendan_Set subprojects in selected items to random custom colors.lua

## My GitHub ReaPack Installation
If you would like to import the scripts here that are not packaged with ReaTeams), copy and paste the following URL in Extensions > ReaPack > Import a Repository:
> https://acendan.github.io/reascripts/index.xml

### Scripts included in my GitHub that are *NOT* included in ReaTeams
 - acendan_Universal Category Renaming Tool.lua
 - acendan_UCS Renaming Tool.html and the respective files in /ucs_libraries
 - acendan_Shrink overlapping regions edges to time selection.lua
 - acendan_Stretch overlapping regions edges to time selection.lua
 - acendan_Shrink overlapping regions to edges of selected media items.lua
 - acendan_Stretch overlapping regions to edges of selected media items.lua
 - acendan_Change region color if region exceeds length.lua
 - acendan_Clear saved URL by track name.lua
 - acendan_Store and Open saved URL by track name.lua
 - acendan_View saved URLs by track name.lua
 - acendan_Random glitchy stutter generator.lua
 - acendan_Clear glitchy stutter generator stored values.lua
 - acendan_Insert marker at start of selected items with item name.lua
 - acendan_Add regions for selected items to render matrix name from active take.lua
 - acendan_Stretch selected items to fit between nearest markers.lua
 - acendan_Append selected items BWF metadata subfield to item name.lua
 - acendan_Set selected items BWF metadata subfield to track name.lua
 - acendan_Insert markers every x seconds after edit cursor.lua
 - acendan_Trim selected items at last zero crossing.lua
 - acendan_Lua Utilities.lua

## Manual Download Instructions (Optional)
If you would prefer to download the scripts here manually, you can click on "Clone or Download", Download as ZIP, and then place the scripts anywhere you would like on your PC. I would recommend placing them within <AppData\Roaming\REAPER\Scripts\>, as they will get included whenever you export or backup your Reaper configuration.

## Special Thanks To
- [X-Raym](https://www.extremraym.com/en/): A ReaScripting guru that inspired me to start writing scripts for Reaper in the first place. He has also directly assisted in code-reviewing the content in this repository.
- [The REAPER Blog](https://reaperblog.net/): A blog run by Jon Tidey, who has helped serve as one of the leading sources for up to date Reaper documentation, tips, tricks, and ideas.
- [cfillion](https://cfillion.ca/): The creator of ReaPack, who has helped to ensure these scripts make it into the hands of far more Reaper users than I'd ever be able to reach solo.
