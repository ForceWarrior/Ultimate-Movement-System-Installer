--// [Variables]
local Content = script.Parent.Parent.Parent.Content.Config
local Settings = require(Content.Settings)
local Blocks = require(Content.Blocks)
local Docs = {}

--// [Do not go past this point]

local function Quote(Text)
	local Safe = Text:gsub("\\", "\\\\")
	Safe = Safe:gsub("\"", "\\\"")
	Safe = Safe:gsub("\n", "\\n")
	return "\"" .. Safe .. "\""
end

local function Sorted(Map)
	local Keys = {}
	for Key in Map do table.insert(Keys, Key) end
	table.sort(Keys)
	return Keys
end

function Docs.Source()
	local Lines = { "--[[", "Made by Force Warrior and Cookie.", "Thank you for purchasing!", "Reselling or distributing this product in any form or by any means is strictly prohibited.", "--]]", "", "return {", "\tSettings = {" }
	for _, Key in Sorted(Settings.Entries) do
		local Entry = Settings.Entries[Key]
		table.insert(Lines, "\t\t[" .. Quote(Key) .. "] = { Summary = " .. Quote(Entry.Summary) .. ", Accepts = " .. Quote(Entry.Accepts) .. " },")
	end
	table.insert(Lines, "\t},")
	table.insert(Lines, "\tBlocks = {")
	for _, Name in Sorted(Blocks.Blocks) do
		table.insert(Lines, "\t\t[" .. Quote(Name) .. "] = " .. Quote(Blocks.Blocks[Name].Summary) .. ",")
	end
	table.insert(Lines, "\t},")
	table.insert(Lines, "}")
	return table.concat(Lines, "\n") .. "\n"
end

return Docs
