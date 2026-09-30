--// [Variables]
local Library = {
	GridTitle = "MODULE LIBRARY",
	Search = "Filter modules",
	Back = "Return",
	Notes = "WORTH KNOWING",
	ExpandHint = "Click an entry to read more.",
	Insert = "Insert",
	Remove = "Remove",
	Facts = function(Files: number): string return Files .. (if Files == 1 then " file" else " files") end,
	BuiltIn = "Built into the kit",
	SettingsTitle = "Settings",
	Status = "Optional modules. Insert puts each file where it goes, Remove takes them out again.",
	Summary = function(Shown: number, Modules: number): string return Shown .. " of " .. Modules .. " modules" end,
	InsertTitle = function(Title: string): string return "Insert " .. Title .. "?" end,
	RemoveTitle = function(Title: string): string return "Remove " .. Title .. "?" end,
	InsertYes = "Yes, insert it",
	RemoveYes = "Yes, remove it",
	ConfirmNo = "Not now",
	DoneTitle = "Inserted",
	RemovedTitle = "Removed",
	DonePlaced = function(Name: string, Into: string): string return Name .. " is in " .. Into .. "." end,
	DoneWaits = function(Name: string, Folder: string): string return Name .. " is in the Workspace folder \"" .. Folder .. "\"." end,
	DoneDeleted = function(Name: string, From: string): string return Name .. " was deleted from " .. From .. "." end,
	DoneClose = "OK",
	DoneConfig = {
		Added = function(Block: string): string return Block .. " was added to MovementConfig with every key at its shipped value." end,
		Present = function(Block: string): string return Block .. " was already in MovementConfig and was left exactly as it is." end,
		Merged = function(Block: string, Keys: string): string return Block .. " was already in MovementConfig and got the keys it lacked: " .. Keys .. "." end,
		Deleted = function(Block: string): string return Block .. " was deleted from MovementConfig." end,
		Kept = function(Block: string): string return Block .. " holds your own values, so it stayed in MovementConfig." end,
		Unreadable = function(Block: string): string return Block .. " is written in a shape the plugin cannot read, so it was left exactly as it is." end,
	},
	FailedTitle = "Nothing was changed",
	Playtest = "Stop the playtest first, nothing inserted or removed during a run survives it.",
	KitMissing = "Install the kit first, the files go into its folders.",
	NoReturn = "MovementConfig has no return Config line, so the block has nowhere to go. Put return Config back at the end of the file.",
	WriteFailed = "MovementConfig could not be written, someone else may have it open in Team Create.",
	BuildFailed = function(Name: string, Problem: string): string return Name .. " could not be built: " .. Problem end,
}

--// [Do not go past this point]

Library.Plan = {
	Placed = function(Name: string, Where: string): string return Name .. " goes into " .. Where end,
	Waits = function(Name: string, Folder: string): string return Name .. " waits in a Workspace folder \"" .. Folder .. "\"" end,
	Deleted = function(Name: string, Where: string): string return Name .. " is deleted from " .. Where end,
	KitFound = function(Version: string): string return "Kit V" .. Version .. " is installed" end,
	BlockAdded = function(Block: string): string return Block .. " is added to MovementConfig with every key at its shipped value" end,
	BlockPresent = function(Block: string): string return Block .. " is already in MovementConfig and stays as it is" end,
	BlockMerged = function(Block: string, Keys: string): string return Block .. " is already in MovementConfig and gets the keys it lacks: " .. Keys end,
	BlockDeleted = function(Block: string): string return Block .. " is deleted from MovementConfig" end,
	BlockKept = function(Block: string): string return Block .. " holds your own values and stays in MovementConfig" end,
	BlockUnreadable = function(Block: string): string return Block .. " is written in a shape the plugin cannot read, it stays exactly as it is and nothing is added to it" end,
	OldFolder = function(Name: string): string return "The Workspace folder \"" .. Name .. "\" from an earlier insert is deleted" end,
	EmoteFound = function(Version: string): string return "Ultimate Emote System V" .. Version .. " is installed" end,
	EmoteUnstamped = function(Needs: string): string return "An Ultimate Emote System without a version stamp is installed, the move needs V" .. Needs .. " or newer" end,
	EmoteOld = function(Version: string, Needs: string): string return "Ultimate Emote System V" .. Version .. " is installed, the move needs V" .. Needs .. " or newer, update it first" end,
	EmoteMissing = function(Needs: string): string return "No Ultimate Emote System found here, the move needs V" .. Needs .. " or newer" end,
	RedTwice = "Red is here twice, under Modules.Util and Modules.Utils, and two copies break the events. The Red in the folder is a one line redirect to the kit's copy, put it in place of Modules > Util > Red",
}

Library.Entries = {
	require(script.EmoteSupport),
	require(script.RagdollSupport),
	require(script.ConfigMenu),
}

function Library.For(Name)
	for _, Entry in Library.Entries do
		if Entry.Name == Name then
			return Entry
		end
	end
	return nil
end

function Library.Setting(Block, Key)
	local Entry = Library.For(Block)
	if Entry and Entry.Settings then
		return Entry.Settings[Key]
	end
	return nil
end

return Library
