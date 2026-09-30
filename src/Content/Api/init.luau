--// [Variables]
local Api = {
	GridTitle = "API REFERENCE",
	Search = "Filter topics",
	Back = "Return",
	Facts = function(Entries: number): string return Entries .. " entries" end,
	NoEntryDoc = "No explanation written for this one yet.",
	Accepts = function(Takes: string): string return "Takes: " .. Takes end,
	ExpandHint = "Click an entry to read what it does.",
	Notes = "WORTH KNOWING",
	Summary = function(Shown: number, Topics: number, Entries: number): string return Shown .. " of " .. Topics .. " topics  |  " .. Entries .. " entries in total" end,
}

--// [Do not go past this point]

Api.Version = "Api version 1  |  system 1.0  |  oldest accepted RequiresApi: 1"

Api.Sections = {
	require(script.Start),
	require(script.Contract),
	require(script.Block),
	require(script.Flags),
	require(script.Kinds),
	require(script.Names),
	require(script.Identity),
	require(script.State),
	require(script.World),
	require(script.Animation),
	require(script.Sound),
	require(script.Stamina),
	require(script.Cooldown),
	require(script.Movement),
	require(script.Camera),
	require(script.Input),
	require(script.Frame),
	require(script.Effects),
	require(script.Outside),
	require(script.Rules),
	require(script.Example),
}

function Api.For(Name)
	for _, Entry in Api.Sections do
		if Entry.Name == Name then
			return Entry
		end
	end
	return nil
end

function Api.Count(Entry)
	return Entry.Rows and #Entry.Rows or 0
end

return Api
