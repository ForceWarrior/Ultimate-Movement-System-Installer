--// [Services]
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local ServerStorage = game:GetService("ServerStorage")
local Selection = game:GetService("Selection")

--// [Modules]
local Content = require(script.Parent.Content)
local ConfigScanner = require(script.Parent.ConfigScanner)
local ConfigDefaults = require(script.Parent.ConfigDefaults)
local PresetCodec = require(script.Parent.PresetCodec)
local KitVersion = require(script.Parent.KitVersion)

--// [Variables]
local Presets = {}
local StoreKey = "UMSInstaller_Presets"
local Handle = nil

--// [Do not go past this point]

local function Trim(Text)
	return (Text or ""):match("^%s*(.-)%s*$")
end

local Counter = 0

local function NewId()
	Counter += 1
	return os.time() .. "-" .. Counter .. "-" .. math.random(100000, 999999)
end

local function StableId(Index, Entry)
	return "kept-" .. Index .. "-" .. tostring(Entry.Name)
end

local function IsAnimationSlot(Path)
	return Path:sub(-11) == "AnimationId"
end

local function IsAddon(Path)
	return Content.Library.For(Path:match("^[%w_]+")) ~= nil
end

local function Size(Map)
	local Total = 0
	for _ in Map do
		Total += 1
	end
	return Total
end

function Presets.Attach(PluginHandle)
	Handle = PluginHandle
	Presets.Migrate()
end

local function Pack(Values)
	local Pairs = {}
	for Path, Value in Values do
		table.insert(Pairs, { Path, Value })
	end
	table.sort(Pairs, function(Left, Right)
		return Left[1] < Right[1]
	end)
	return Pairs
end

local function Unmangle(Map)
	local Module = ConfigScanner.Module()
	local Real = {}
	if Module then
		for _, Row in ConfigScanner.ScanAll(Module.Source) do
			Real[(Row.Path:gsub("%.", "_"))] = Row.Path
		end
	end
	local Values = {}
	for Key, Value in Map do
		Values[Real[Key] or Key] = Value
	end
	return Values
end

local function Unpack(Stored)
	if typeof(Stored) ~= "table" then
		return {}
	end
	if Stored[1] ~= nil then
		local Values = {}
		for _, Pair in Stored do
			if typeof(Pair) == "table" and typeof(Pair[1]) == "string" then
				Values[Pair[1]] = Pair[2]
			end
		end
		return Values
	end
	return Unmangle(Stored)
end

local function Convert(Entry)
	if Entry.Source and not Entry.Values then
		local Values = ConfigScanner.Values(Entry.Source)
		return {
			Id = Entry.Id,
			Name = Entry.Name,
			Description = Entry.Description,
			Values = Values,
			Count = Size(Values),
			Partial = false,
		}
	end
	Entry.Values = Unpack(Entry.Values)
	return Entry
end

local function Read()
	local Stored = Handle and Handle:GetSetting(StoreKey)
	if typeof(Stored) ~= "table" then
		return {}
	end
	local List = {}
	for Index, Entry in Stored do
		if typeof(Entry) == "table" and Entry.Name then
			local Row = Convert(Entry)
			Row.Id = Row.Id or StableId(Index, Row)
			List[Index] = Row
		end
	end
	return List
end

local function Write(List)
	if not Handle then
		return false, "no plugin handle"
	end
	local Packed = {}
	for Index, Entry in List do
		local Copy = table.clone(Entry)
		Copy.Values = Pack(Entry.Values or {})
		Packed[Index] = Copy
	end
	Handle:SetSetting(StoreKey, Packed)

	local Back = Handle:GetSetting(StoreKey)
	if typeof(Back) ~= "table" or #Back ~= #List then
		return false, "the change did not reach the plugin's saved settings, so nothing was kept"
	end
	for Index, Entry in List do
		local Mirror = Back[Index]
		if not Mirror or Mirror.Id ~= Entry.Id or Size(Unpack(Mirror.Values)) ~= Size(Entry.Values or {}) then
			return false, "the save came back changed, nothing was kept"
		end
	end
	return true, nil
end

local function Store(Entry)
	local List = Read()
	Entry.Id = Entry.Id or NewId()
	table.insert(List, Entry)
	local Ok, Problem = Write(List)
	return Ok, Problem
end

function Presets.Migrate()
	if not Handle then
		return false
	end
	local Stored = Handle:GetSetting(StoreKey)
	if typeof(Stored) ~= "table" then
		return false
	end
	local Stale = 0
	for _, Entry in Stored do
		if typeof(Entry) == "table" and Entry.Name then
			if not Entry.Id then
				Entry.Id = NewId()
				Stale += 1
			end
			if typeof(Entry.Values) == "table" and Entry.Values[1] == nil and next(Entry.Values) ~= nil then
				Stale += 1
			end
		end
	end
	if Stale == 0 then
		return false
	end
	local List = {}
	for Index, Entry in Stored do
		if typeof(Entry) == "table" and Entry.Name then
			List[Index] = Convert(Entry)
		end
	end
	return Write(List)
end

function Presets.List()
	return Read()
end

function Presets.Find(Id)
	for _, Entry in Read() do
		if Entry.Id == Id then
			return Entry
		end
	end
	return nil
end

function Presets.Save(Name, Description)
	Name = Trim(Name)
	if Name == "" then
		return false, "give it a name first"
	end

	local Module = ConfigScanner.Module()
	if not Module then
		return false, "MovementConfig not found in this place"
	end

	local Report = ConfigScanner.LeafSelfTest(Module.Source)
	if not Report.Trustworthy then
		return false, "the config does not read back cleanly, refusing to store it"
	end

	local Values = {}
	for _, Row in Report.Rows do
		Values[Row.Path] = Row.Raw
	end

	local Ok, Problem = Store({
		Name = Name,
		Description = Trim(Description),
		Values = Values,
		Count = Report.Count,
		Partial = false,
		Version = KitVersion.Live(),
	})
	if not Ok then
		return false, Problem
	end
	return true, "saved"
end

function Presets.Delete(Id)
	local List = Read()
	for Index, Entry in List do
		if Entry.Id == Id then
			table.remove(List, Index)
			return Write(List)
		end
	end
	return false, "that preset is not in the list any more"
end

function Presets.Backup(Module)
	local Copy = Module:Clone()
	Copy.Name = Module.Name .. "_BeforePreset"
	local Previous = ServerStorage:FindFirstChild(Copy.Name)
	if Previous then
		Previous.Parent = nil
	end
	Copy.Parent = ServerStorage
	return Copy
end

local function Rewrite(Source, Wanted)
	local Rows = ConfigScanner.ScanAll(Source)
	if #Rows == 0 then
		return nil, "nothing readable in the config"
	end

	local Values, Known = {}, {}
	for _, Row in Rows do
		Values[Row.Path] = Row.Raw
		Known[Row.Path] = true
	end

	local Changed, Unknown, Animations = 0, 0, 0
	for Path, Value in Wanted do
		if not Known[Path] then
			Unknown += 1
		elseif Values[Path] ~= Value then
			Values[Path] = Value
			Changed += 1
			if IsAnimationSlot(Path) then
				Animations += 1
			end
		end
	end

	local Candidate = ConfigScanner.Splice(Source, Rows, Values)

	local Check = ConfigScanner.ScanAll(Candidate)
	if #Check ~= #Rows then
		return nil, "the rewrite changed how many settings the file holds"
	end
	for Index, Row in Check do
		if Row.Path ~= Rows[Index].Path then
			return nil, "the rewrite moved " .. Rows[Index].Path
		end
	end

	local _, Before = Source:gsub("\n", "")
	local _, After = Candidate:gsub("\n", "")
	if Before ~= After then
		return nil, "the rewrite changed the line count"
	end

	if type(loadstring) == "function" then
		local Chunk = loadstring(Candidate)
		if not Chunk then
			return nil, "the rewrite would not compile, nothing was written"
		end
	end

	return Candidate, nil, Changed, Unknown, Animations
end

local Markers = {
	"loadstring", "getfenv", "setfenv", "getgenv", "_G.", "_G[", "GetService", "HttpService",
	"MarketplaceService", "TeleportService", "InsertService", "game.", "game:", "script.",
	"string.char", "string.reverse",
}

local Shapes = {
	{ Pattern = "require%s*%(%s*%d", Marker = "require(id)" },
	{ Pattern = "\\%d%d%d", Marker = "escaped bytes" },
	{ Pattern = "%f[%w_]function%f[^%w_]", Marker = "function" },
}

local function MarkersIn(Text)
	local Found = {}
	if type(Text) ~= "string" then
		return Found
	end
	for _, Marker in Markers do
		if Text:find(Marker, 1, true) then
			table.insert(Found, Marker)
		end
	end
	for _, Shape in Shapes do
		if Text:find(Shape.Pattern) then
			table.insert(Found, Shape.Marker)
		end
	end
	return Found
end

function Presets.Inspect(Values)
	local Findings = {}
	if type(Values) ~= "table" then
		return Findings
	end
	local Rows = {}
	for Path, Value in Values do
		table.insert(Rows, { Path = tostring(Path), Value = Value })
	end

	table.sort(Rows, function(Left, Right)
		return Left.Path < Right.Path
	end)
	for _, Row in Rows do
		for _, Marker in MarkersIn(Row.Value) do
			table.insert(Findings, Row.Path .. ": " .. Marker)
		end
	end
	return Findings
end

function Presets.InspectSource(Text, OnlyLines)
	local Findings = {}
	if type(Text) ~= "string" then
		return Findings
	end
	local Line, Start = 1, 1
	while true do
		local Stop = Text:find("\n", Start, true)
		local Row = Text:sub(Start, (Stop or (#Text + 1)) - 1)
		if not OnlyLines or OnlyLines[Line] then
			for _, Marker in MarkersIn(Row) do
				table.insert(Findings, "line " .. Line .. ": " .. Marker)
			end
		end
		if not Stop then
			break
		end
		Start = Stop + 1
		Line += 1
	end
	return Findings
end

local function ChangedLines(Before, After)
	local Old = {}
	for Row in (Before .. "\n"):gmatch("([^\n]*)\n") do
		table.insert(Old, Row)
	end
	local Lines, Index = {}, 0
	for Row in (After .. "\n"):gmatch("([^\n]*)\n") do
		Index += 1
		if Row ~= Old[Index] then
			Lines[Index] = true
		end
	end
	return Lines
end

function Presets.Preview(Id)
	local Entry = Presets.Find(Id)
	local Module = ConfigScanner.Module()
	if not Entry or not Module then
		return 0, 0, 0, {}
	end
	local Findings = Presets.Inspect(Entry.Values)
	local _, Problem, Changed, Unknown, Animations = Rewrite(Module.Source, Entry.Values)

	if Problem then
		return 0, 0, 0, Findings, Problem
	end
	return Changed, Unknown, Animations, Findings, nil
end

function Presets.PreviewInsert(Id)
	local Entry = Presets.Find(Id)
	local Live = ConfigScanner.Module()
	if not Entry or not Live then
		return 0, 0, 0, {}
	end
	local Candidate, Problem, Changed, Unknown, Animations = Rewrite(Live.Source, Entry.Values)
	if not Candidate then
		return 0, 0, 0, Presets.Inspect(Entry.Values), Problem
	end
	local Findings = Presets.InspectSource(Candidate, ChangedLines(Live.Source, Candidate))
	return Changed, Unknown, Animations, Findings, nil
end

function Presets.Compatibility(Entry)
	local Live = KitVersion.Live()
	local Made = Entry and Entry.Version or nil
	return KitVersion.Compare(Made, Live), Made, Live
end

function Presets.Apply(Id)
	local Entry = Presets.Find(Id)
	if not Entry then
		return false, "that preset is not in the list any more"
	end

	local Module = ConfigScanner.Module()
	if not Module then
		return false, "MovementConfig not found in this place"
	end

	Presets.Backup(Module)

	local Recording = ChangeHistoryService:TryBeginRecording("UMSPreset", "Apply movement config preset")
	local Wrote, Reason, Changed, Unknown = false, "the write was refused", 0, 0

	ScriptEditorService:UpdateSourceAsync(Module, function(Old)
		local Candidate, Problem, Did, Missed = Rewrite(Old, Entry.Values)
		if not Candidate then
			Reason = Problem
			return nil
		end
		Wrote, Changed, Unknown = true, Did, Missed
		return Candidate
	end)

	if Recording then
		ChangeHistoryService:FinishRecording(Recording, Enum.FinishRecordingOperation.Commit)
	end

	if not Wrote then
		return false, Reason
	end

	for _ = 1, 60 do
		local Now = ConfigScanner.Values(Module.Source)
		local Settled = true
		for Path, Value in Entry.Values do
			if Now[Path] ~= nil and Now[Path] ~= Value then
				Settled = false
				break
			end
		end
		if Settled then
			break
		end
		task.wait(0.05)
	end

	if Unknown > 0 then
		return true, "applied \"" .. Entry.Name .. "\", " .. Changed .. " settings changed, " .. Unknown .. " not in this config"
	end
	return true, "applied \"" .. Entry.Name .. "\", " .. Changed .. " settings changed"
end

function Presets.InsertTarget()
	local Chosen = Selection:Get()[1]
	if Chosen and not Chosen:IsA("LuaSourceContainer") then
		return Chosen
	end
	if Chosen and Chosen.Parent then
		return Chosen.Parent
	end
	return game:GetService("ReplicatedStorage")
end

function Presets.Insert(Id, Target)
	local Entry = Presets.Find(Id)
	if not Entry then
		return false, "that preset is not in the list any more"
	end

	local Live = ConfigScanner.Module()
	if not Live then
		return false, "MovementConfig not found in this place, so there is nothing to build from"
	end

	local Candidate, Problem = Rewrite(Live.Source, Entry.Values)
	if not Candidate then
		return false, Problem
	end

	local Where = Target or Presets.InsertTarget()
	local Recording = ChangeHistoryService:TryBeginRecording("UMSPresetInsert", "Insert movement config preset")

	local Module = Instance.new("ModuleScript")
	Module.Name = "MovementConfig"
	Module.Parent = Where
	ScriptEditorService:UpdateSourceAsync(Module, function()
		return Candidate
	end)
	Selection:Set({ Module })

	if Recording then
		ChangeHistoryService:FinishRecording(Recording, Enum.FinishRecordingOperation.Commit)
	end
	return true, "inserted " .. Module.Name .. " into " .. Where:GetFullName()
end

function Presets.Changed(Entry, IncludeAnimations)
	local Paths, Values = {}, {}
	for Path, Value in Entry.Values do
		local Default = ConfigDefaults.Values[Path]
		local Skip = (IsAnimationSlot(Path) and not IncludeAnimations) or IsAddon(Path)
		if not Skip and Default ~= Value then
			table.insert(Paths, Path)
			Values[Path] = Value
		end
	end

	table.sort(Paths)
	return Paths, Values
end

function Presets.Code(Id, IncludeAnimations)
	local Entry = Presets.Find(Id)
	if not Entry then
		return nil, "that preset is not in the list any more"
	end

	local Paths, Values = Presets.Changed(Entry, IncludeAnimations)
	if #Paths == 0 then
		return nil, "this preset matches the shipped defaults, there is nothing to share"
	end

	local Ok, Problem = PresetCodec.SelfTest(Entry.Name, Entry.Description, Values, Paths, Entry.Version)
	if not Ok then
		return nil, "the code did not survive its own round trip: " .. tostring(Problem)
	end

	local Code = PresetCodec.Encode(Entry.Name, Entry.Description, Values, Paths, Entry.Version)
	return Code, nil, #Paths
end

function Presets.Adopt(Text)
	local Read, Problem = PresetCodec.Decode(Text)
	if not Read then
		return false, nil, Problem
	end

	local Entry = {
		Name = Read.Name,
		Description = Read.Description,
		Values = Read.Values,
		Count = Read.Count,
		Partial = true,
		Version = Read.Version,
	}

	local Ok, Trouble = Store(Entry)
	if not Ok then
		return false, Read.Name, Trouble
	end
	return true, Read.Name, nil
end

return Presets
