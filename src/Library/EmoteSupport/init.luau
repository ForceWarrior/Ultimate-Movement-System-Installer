--// [Services]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// [Modules]
local Content = require(script.Parent.Parent.Content)
local KitVersion = require(script.Parent.Parent.KitVersion)

--// [Variables]
local EmoteSupport = {}

--// [Do not go past this point]

EmoteSupport.Folder = "UltimateEmoteSystem Support"
EmoteSupport.NeedsFrom = "1.1"

EmoteSupport.ConfigBlock = { Name = "EmoteSupport", Source = [==[
Config.EmoteSupport = {
	--// [Toggles]
	Enabled = true,
	StopEmoteOnMove = true,
	--// [Lists]
	IgnoredMoves = {},
}]==] }

local function EmoteVersion(Folder)
	local Stamp = Folder and Folder:GetAttribute(KitVersion.Attribute)
	if typeof(Stamp) == "number" then
		return tostring(Stamp)
	end
	if typeof(Stamp) == "string" and Stamp ~= "" then
		return Stamp
	end
	return nil
end

local function RedAt(FolderName)
	local Modules = ReplicatedStorage:FindFirstChild("Modules")
	local Folder = Modules and Modules:FindFirstChild(FolderName)
	local Red = Folder and Folder:FindFirstChild("Red")
	if Red and Red:IsA("ModuleScript") then
		return Red
	end
	return nil
end

local function IsRedirect(Module)
	if not Module then
		return false
	end
	local Code = Module.Source:gsub("%-%-[^\n]*", "")
	return Code:match("^%s*return%s+require%(") ~= nil
end

function EmoteSupport.Detect()

	local Modules = ReplicatedStorage:FindFirstChild("Modules")
	local Folder = (Modules and Modules:FindFirstChild("EmoteSystem")) or ReplicatedStorage:FindFirstChild("EmoteSystem")
	local Version = EmoteVersion(Folder)
	local Emote = {
		Present = Folder ~= nil,
		Version = Version,
		Recent = Version ~= nil and KitVersion.AtLeast(Version, EmoteSupport.NeedsFrom),
	}

	local EmoteRed, KitRed = RedAt("Util"), RedAt("Utils")
	local Red = {
		Twice = EmoteRed ~= nil and KitRed ~= nil and not IsRedirect(EmoteRed) and not IsRedirect(KitRed),
	}

	return { Emote = Emote, Red = Red }
end

function EmoteSupport.Files(Facts)
	local Files = {
		{ Name = "EmoteSupport", Class = "ModuleScript", Source = require(script.Module), Where = Facts.Kit.Custom },
	}
	if Facts.Red.Twice then

		table.insert(Files, { Name = "Red", Class = "ModuleScript", Source = require(script.RedRedirect) })
	end
	return Files
end

function EmoteSupport.Describe(Facts)
	local Plan = Content.Library.Plan
	local Lines, Warnings = {}, {}
	if not Facts.Emote.Present then
		table.insert(Warnings, Plan.EmoteMissing(EmoteSupport.NeedsFrom))
	elseif Facts.Emote.Recent then
		table.insert(Lines, Plan.EmoteFound(tostring(Facts.Emote.Version)))
	elseif Facts.Emote.Version then
		table.insert(Warnings, Plan.EmoteOld(tostring(Facts.Emote.Version), EmoteSupport.NeedsFrom))
	else
		table.insert(Warnings, Plan.EmoteUnstamped(EmoteSupport.NeedsFrom))
	end

	if Facts.Red.Twice then
		table.insert(Warnings, Plan.RedTwice)
	end
	return Lines, Warnings
end

return EmoteSupport
