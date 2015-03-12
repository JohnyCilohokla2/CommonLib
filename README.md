# CommonLib
CommonLib for TUG (The Untitled Game)

To add it to TUG:

1. Drop all of the files to /TUG/Mods/CommonLib/

2. Add "Mods/CommonLib" to mods.txt (has to be below "Game/Core", preferably last)



It will make mods load their main classes, you might want to get rid of the "Mods/TestModScript" as it will cause lua pop up.

If will also expose chat commands to mods, you can use Eternus.GameState:RegisterSlashCommand("Command", self, "CommandFunction") to register /command pointing to self:CommandFunction(args), self it an instance of your mod when called from your mod(this is usually where you will want to register commands).

http://johny.ovh/
