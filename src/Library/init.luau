--// [Services]
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local Selection = game:GetService("Selection")

--// [Modules]
local Content = require(script.Parent.Content)
local KitVersion = require(script.Parent.KitVersion)
local ConfigScanner = require(script.Parent.ConfigScanner)

--// [Variables]
local Library = {}
local Notice = "--[[\nMade by Force Warrior and Cookie.\nThank you for purchasing!\nReselling or distributing this product in any form or by any means is strictly prohibited.\n--]]\n\n"

--// [Do not go past this point]

local function Stamped(Source)
	if Source:sub(1, #Notice) == Notice then
		return Source
	end
	return Notice .. Source
end

Library.Builders = {}
for _, Entry in Content.Library.Entries do
	local Builder = script:FindFirstChild(Entry.Name)
	if Builder then
		Library.Builders[Entry.Name] = require(Builder)
	end
end

local function Short(Where)
	local Path = Where:GetFullName():gsub("^ReplicatedStorage%.Modules%.Movement%.", "")
	return (Path:gsub("%.", " > "))
end

local function KitFacts()
	local Config = ConfigScanner.Module()
	local Main = Config and Config.Parent:FindFirstChild("MovementMain")
	return {
		Config = Config,
		Version = KitVersion.Live(),
		Custom = Main and Main:FindFirstChild("Custom") or nil,
	}
end

local function Refusal(Kit)
	if RunService:IsRunning() then
		return Content.Library.Playtest
	end
	if not Kit.Custom then
		return Content.Library.KitMissing
	end
	return nil
end

local function Waiting(Plan)
	local Folder = Plan.Folder and workspace:FindFirstChild(Plan.Folder)
	if Folder and Folder:IsA("Folder") then
		return Folder
	end
	return nil
end

local function FindBlock(Source, Name)
	local Code = ConfigScanner.Mask(Source)
	local Start, Open = Code:find("\nConfig%." .. Name .. "%s*=%s*{")
	if not Start then
		return Code:find("\nConfig%." .. Name .. "%s*=") ~= nil
	end
	local Depth = 0
	for Index = Open, #Code do
		local Char = Code:sub(Index, Index)
		if Char == "{" then
			Depth += 1
		elseif Char == "}" then
			Depth -= 1
			if Depth == 0 then
				if Code:sub(Index - 1, Index - 1) == "\n" then
					return true, Start + 1, Index
				end
				return true
			end
		end
	end
	return true
end

local function TopKeys(Text)
	local Code = ConfigScanner.Mask(Text)
	local Keys = {}
	local Depth = 0
	local Index = 1
	while Index <= #Code do
		local Char = Code:sub(Index, Index)
		if Char == "{" then
			Depth += 1
			Index += 1
		elseif Char == "}" then
			Depth -= 1
			Index += 1
		elseif Char:match("[%a_]") then
			local Word = Code:match("^[%a_][%w_]*", Index)
			if Depth == 1 and Code:match("^%s*=[^=]", Index + #Word) then
				Keys[Word] = true
			end
			Index += #Word
		else
			Index += 1
		end
	end
	return Keys
end

local function MissingLines(Text, Block)
	local Have = TopKeys(Text)
	local Missing = {}
	for Line in Block.Source:gmatch("[^\n]+") do
		local Key = Line:match("^\t([%a_][%w_]*) = ")
		if Key and not Have[Key] then
			table.insert(Missing, { Key = Key, Line = Line })
		end
	end
	return Missing
end

local function KeyNames(Missing)
	local Names = {}
	for _, Entry in Missing do
		table.insert(Names, Entry.Key)
	end
	return table.concat(Names, ", ")
end

local function BlockState(Source, Block)
	local Found, First, Last = FindBlock(Source, Block.Name)
	if not Found then
		return { Found = false, Return = Source:find("\nreturn Config", 1, true) ~= nil }
	end
	if not First then
		return { Found = true, Unreadable = true }
	end
	local Text = Source:sub(First, Last)
	return { Found = true, Shipped = Text == Block.Source, Missing = MissingLines(Text, Block), First = First, Last = Last }
end

local function WithBlock(Source, Block)
	local Label = "Config." .. Block.Name
	local State = BlockState(Source, Block)
	if State.Unreadable then
		return nil, Content.Library.DoneConfig.Unreadable(Label)
	end
	if State.Found and #State.Missing == 0 then
		return nil, Content.Library.DoneConfig.Present(Label)
	end
	if State.Found then
		local Head = Source:sub(1, State.Last - 1)
		local Code = ConfigScanner.Mask(Head)

		local After = Code:match("()%S%s*$")
		if After and not Code:sub(After, After):match("[,;{]") then
			Head = Head:sub(1, After) .. "," .. Head:sub(After + 1)
		end
		local Lines = {}
		for _, Entry in State.Missing do
			table.insert(Lines, Entry.Line)
		end
		return Head .. table.concat(Lines, "\n") .. "\n" .. Source:sub(State.Last), Content.Library.DoneConfig.Merged(Label, KeyNames(State.Missing))
	end
	local Tail = Source:find("\nreturn Config", 1, true)
	if not Tail then
		return nil, nil, Content.Library.NoReturn
	end
	local Head = Source:sub(1, Tail - 1):gsub("%s+$", "")
	local Body = Block.Source:gsub("%s+$", "")
	return Head .. "\n\n" .. Body .. "\n\n" .. Source:sub(Tail + 1), Content.Library.DoneConfig.Added(Label)
end

local function WithoutBlock(Source, Block)
	local Label = "Config." .. Block.Name
	local State = BlockState(Source, Block)
	if not State.Found then
		return nil, nil
	end
	if State.Unreadable then
		return nil, Content.Library.DoneConfig.Unreadable(Label)
	end
	if not State.Shipped then
		return nil, Content.Library.DoneConfig.Kept(Label)
	end
	local Head = Source:sub(1, State.First - 1):gsub("%s+$", "")
	local Rest = Source:sub(State.Last + 1):gsub("^%s+", "")
	return Head .. "\n\n" .. Rest, Content.Library.DoneConfig.Deleted(Label)
end

local function WriteConfig(Config, Block, Change)
	local Ran, Line, Problem = false, nil, nil
	local Ok = pcall(function()
		ScriptEditorService:UpdateSourceAsync(Config, function(Old)
			local Text
			Ran = true
			Text, Line, Problem = Change(Old, Block)
			return Text
		end)
	end)
	if not Ok or not Ran then
		return nil, Content.Library.WriteFailed
	end
	return Line, Problem
end

local function Removal(Plan, Block)
	local Words = Content.Library.Plan
	if Block and Block.Found then
		local Label = "Config." .. Plan.ConfigBlock.Name
		if Block.Unreadable then
			table.insert(Plan.Lines, Words.BlockUnreadable(Label))
		elseif Block.Shipped then
			table.insert(Plan.Lines, Words.BlockDeleted(Label))
		else
			table.insert(Plan.Lines, Words.BlockKept(Label))
		end
	end
	for _, File in Plan.Files do
		if File.Where and File.Where:FindFirstChild(File.Name) then
			table.insert(Plan.Lines, Words.Deleted(File.Name, Short(File.Where)))
		end
	end
	if Waiting(Plan) then
		table.insert(Plan.Lines, Words.OldFolder(Plan.Folder))
	end
end

local function Addition(Plan, Builder, Facts, Block)
	local Words = Content.Library.Plan
	if Waiting(Plan) then
		table.insert(Plan.Lines, Words.OldFolder(Plan.Folder))
	end
	for _, File in Plan.Files do
		if File.Old then
			continue
		end
		if File.Where then
			table.insert(Plan.Lines, Words.Placed(File.Name, Short(File.Where)))
		else
			table.insert(Plan.Lines, Words.Waits(File.Name, Plan.Folder))
		end
	end
	table.insert(Plan.Lines, "")
	table.insert(Plan.Lines, Words.KitFound(tostring(Facts.Kit.Version)))
	if Block then
		local Label = "Config." .. Plan.ConfigBlock.Name
		if not Block.Found then
			table.insert(Plan.Lines, Words.BlockAdded(Label))
		elseif Block.Unreadable then
			table.insert(Plan.Lines, Words.BlockUnreadable(Label))
		elseif #Block.Missing > 0 then
			table.insert(Plan.Lines, Words.BlockMerged(Label, KeyNames(Block.Missing)))
		else
			table.insert(Plan.Lines, Words.BlockPresent(Label))
		end
		if not Block.Found and not Block.Return then
			Plan.Problem = Content.Library.NoReturn
		end
	end
	local Lines, Warnings = Builder.Describe(Facts)
	table.move(Lines, 1, #Lines, #Plan.Lines + 1, Plan.Lines)
	table.move(Warnings, 1, #Warnings, #Plan.Warnings + 1, Plan.Warnings)
end

function Library.Plan(Name)
	local Builder = Library.Builders[Name]
	if not Builder then
		return nil
	end
	local Kit = KitFacts()
	local Facts = Builder.Detect()
	Facts.Kit = Kit
	local Plan = {
		Name = Name,
		Title = Content.Library.For(Name).Title,
		Folder = Builder.Folder,
		ConfigBlock = Builder.ConfigBlock,
		Files = Builder.Files(Facts),
		Count = 0,
		Present = false,
		Problem = Refusal(Kit),
		Lines = {},
		Warnings = {},
	}

	for _, File in Plan.Files do
		if not File.Old then
			Plan.Count += 1
		end
		if not File.Old and File.Where and File.Where:FindFirstChild(File.Name) then
			Plan.Present = true
		end
	end
	if Plan.Problem then
		return Plan
	end
	local Block = if Plan.ConfigBlock then BlockState(Kit.Config.Source, Plan.ConfigBlock) else nil
	if Plan.Present then
		Removal(Plan, Block)
	else
		Addition(Plan, Builder, Facts, Block)
	end
	return Plan
end

local function Finish(Recording, Operation)
	if Recording then
		ChangeHistoryService:FinishRecording(Recording, Operation)
	end
end

local function Made(File)
	local Item
	if File.Make then
		Item = File.Make()
	else
		Item = Instance.new(File.Class)
		Item.Source = Stamped(File.Source)
	end
	Item.Name = File.Name
	return Item
end

local function Discard(Items)
	for _, Item in Items do
		Item:Destroy()
	end
end

function Library.Insert(Plan)
	local Kit = KitFacts()
	local Problem = Refusal(Kit)
	if Problem then
		return false, Problem
	end
	local Built = {}
	local Items = {}
	for _, File in Plan.Files do
		if File.Old then
			continue
		end
		local Ok, Item = pcall(Made, File)
		if not Ok then
			Discard(Items)
			return false, Content.Library.BuildFailed(File.Name, tostring(Item))
		end
		table.insert(Built, { File = File, Item = Item })
		table.insert(Items, Item)
	end

	local Recording = ChangeHistoryService:TryBeginRecording("UMSLibraryInsert", "Insert " .. Plan.Title)
	local Said = {}
	if Plan.ConfigBlock then
		local Line, Failed = WriteConfig(Kit.Config, Plan.ConfigBlock, WithBlock)
		if Failed then
			Discard(Items)
			Finish(Recording, Enum.FinishRecordingOperation.Cancel)
			return false, Failed
		end
		if Line then
			table.insert(Said, Line)
		end
	end

	local Stale = Waiting(Plan)
	if Stale then
		Stale:Destroy()
		table.insert(Said, Content.Library.DoneDeleted(Plan.Folder, Short(workspace)))
	end
	local Folder = nil
	for _, Pair in Built do
		local File = Pair.File
		if File.Where then
			local Existing = File.Where:FindFirstChild(File.Name)
			if Existing then
				Existing:Destroy()
			end
			Pair.Item.Parent = File.Where
			table.insert(Said, Content.Library.DonePlaced(File.Name, Short(File.Where)))
		else
			if not Folder then
				Folder = Instance.new("Folder")
				Folder.Name = Plan.Folder
				Folder.Parent = workspace
			end
			Pair.Item.Parent = Folder
			table.insert(Said, Content.Library.DoneWaits(File.Name, Plan.Folder))
		end
	end
	Selection:Set(Items)

	Finish(Recording, Enum.FinishRecordingOperation.Commit)
	return true, Said
end

function Library.Remove(Plan)
	local Kit = KitFacts()
	local Problem = Refusal(Kit)
	if Problem then
		return false, Problem
	end
	local Recording = ChangeHistoryService:TryBeginRecording("UMSLibraryRemove", "Remove " .. Plan.Title)
	local Said = {}
	if Plan.ConfigBlock then
		local Line, Failed = WriteConfig(Kit.Config, Plan.ConfigBlock, WithoutBlock)
		if Failed then
			Finish(Recording, Enum.FinishRecordingOperation.Cancel)
			return false, Failed
		end
		if Line then
			table.insert(Said, Line)
		end
	end
	for _, File in Plan.Files do
		local Item = File.Where and File.Where:FindFirstChild(File.Name)
		if Item then
			table.insert(Said, Content.Library.DoneDeleted(File.Name, Short(File.Where)))
			Item:Destroy()
		end
	end
	local Folder = Waiting(Plan)
	if Folder then
		Folder:Destroy()
		table.insert(Said, Content.Library.DoneDeleted(Plan.Folder, Short(workspace)))
	end
	Finish(Recording, Enum.FinishRecordingOperation.Commit)
	return true, Said
end

return Library
