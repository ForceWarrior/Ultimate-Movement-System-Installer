--// [Variables]
local Config = {
	GridTitle = "CONFIG BLOCKS",
	Search = "Filter blocks",
	Back = "Return",
	Facts = function(Settings: number): string return Settings .. " settings" end,
	NoDoc = "no description yet",
	NoSettingDoc = "No explanation written for this one yet.",
	Accepts = function(Takes: string): string return "Takes: " .. Takes end,
	OwnComment = function(Comment: string): string return "In the file: " .. Comment end,
	ExpandHint = "Click a setting to read what it does. Everything here is read straight out of "
		.. "MovementConfig, so editing the file updates this page as you type.",
	FunctionValue = "function(Context) ... end",
	LinePrefix = "line ",
	Notes = "WORTH KNOWING",
	Where = function(Block: string, First: number, Last: number): string return Block .. ", lines " .. First .. " to " .. Last .. " of MovementConfig" end,
	Summary = function(Shown: number, Blocks: number, Settings: number): string return Shown .. " of " .. Blocks .. " blocks  |  " .. Settings .. " settings in total" end,
	NoConfig = "MovementConfig not found. Install the folders first.",
}

--// [Do not go past this point]

Config.Blocks = require(script.Blocks)
Config.Settings = require(script.Settings)

return Config
