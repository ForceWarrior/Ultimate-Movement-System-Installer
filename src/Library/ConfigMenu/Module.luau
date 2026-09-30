return [==[
--[[
Made by Force Warrior and Cookie.
Thank you for purchasing!
Reselling or distributing this product in any form or by any means is strictly prohibited.
--]]

--// [Services]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

--// [Modules]
local Movement = script:FindFirstAncestor("Movement")
local MovementTypes = require(Movement.MovementTypes)
local ConfigValidator = require(Movement.Engine.ConfigValidator)
local MovementConfig = require(Movement.MovementConfig)
local Trove = require(ReplicatedStorage.Modules.Utils.Trove)
local ContextActionUtility = require(ReplicatedStorage.Modules.Utils.ContextActionUtility)

--// [Variables]

type Table = { [unknown]: unknown }
type Place = { Name: string, Key: unknown, Table: Table, Path: string, Spelled: string, Block: string, Parent: Place? }
type Change = { Place: Place, Key: unknown, Before: unknown, Order: number }
type Spot = { Place: Place, Key: unknown }
type Entry = { Place: Place, Key: unknown, Path: string, KeyText: string, PathText: string, ValueText: string, PathValue: string, AllText: string, Rank: number }
type DocLine = { Summary: string, Accepts: string }
type Docs = { Settings: { [string]: DocLine }, Blocks: { [string]: string } }
type Settings = { Enabled: boolean, StudioOnly: boolean, OpenKey: Enum.KeyCode, OpenButton: Enum.KeyCode, Scale: number }

local Api = nil
local Lifetime = Trove.new()
local Gui: ScreenGui? = nil
local Templates = script:FindFirstChild("Templates")
local Parts: {[string]: Instance} = {}
local Whole: { [string]: Table } = MovementConfig
local Scrolls: { [Table]: Vector2 } = {}
local Spots: { [Instance]: Spot } = {}
local Changes: { [Table]: { [unknown]: Change } } = {}
local KeyTables: { [string]: boolean } = {}
local WholeList = {}
local ChangeOrder = 0
local Trail: { Place } = {}
local Trails: { [string]: { Place } } = {}
local Built: { [Table]: { [unknown]: GuiObject } } = {}
local LastBlock = "Core"
local View = "Browse"
local Query = ""
local Found: { Entry } = {}
local SearchToken = 0
local Index: { Entry }? = nil
local Problems: { string } = {}
local Pinned: Spot? = nil
local Hovered: Spot? = nil
local Notice: string? = nil
local Docs: Docs? = nil
local DocsLooked = false
local Pending = false
local CountMoved = false
local Armed = false
local ArmToken = 0
local HoldToken = 0
local Repeating = false
local WasOpen = false
local TouchOnly = false
local PassedBack = false
local RowsLinked = false
local PickerAnchor: GuiObject? = nil
local Capturing: { Spot: Spot, Button: TextButton, Wants: string, Since: number }? = nil
local Listening: RBXScriptConnection? = nil
local Focusing: RBXScriptConnection? = nil
local Selecting: RBXScriptConnection? = nil
local Dragging: RBXScriptConnection? = nil
local Releasing: RBXScriptConnection? = nil
local Rendering = false
local Render, Show, OpenTable, JumpTo, ArmOrRevert, ReloadKit, ExportChanges
local MostResults = 40
local SearchDelay = 0.15
local WalkDepth = 6
local HoldDelay = 0.4
local HoldRate = 0.07
local ArmTime = 3
local CaptureGrace = 0.15
local MinGrouped = 8
local MostCrumbs = 5
local PickerRows = 8
local LongSummary = 150
local KindTitles = { "Switches", "Modes", "Keys", "Numbers", "Text", "Sounds", "Animations", "Effects", "Tables", "Functions" }
local EffectTables = { CameraShake = true, FOV = true, SprintFOV = true, Haptics = true }
local Reserved = { ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true, ["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true, ["while"] = true }
local Controls = { "Toggle", "Field", "Pick", "Choose", "Open", "Add", "Export" }
local WindowParts = { "Window", "Title", "Changes", "Validate", "Reload", "Close", "Search", "ClearSearch", "Blocks", "Crumbs", "Up", "Path", "Rows", "Output", "Heading", "Select", "Dismiss", "Scroll", "Text", "Info", "Setting", "More", "Revert", "Facts", "Summary", "Picker", "UIScale" }
local TemplateNames = { "Section", "Block", "Crumb", "Heading", "ToggleRow", "NumberRow", "TextRow", "KeyRow", "ChoiceRow", "TableRow", "InfoRow", "AddRow", "ActionRow", "Option" }

local ConfigMenu = {}
ConfigMenu.Name = script.Name
ConfigMenu.RequiresApi = 1

--// [Do not go past this point]

local function Round(Value: number): string
	if Value == math.floor(Value) then return tostring(Value) end
	return tostring(math.round(Value * 1000) / 1000)
end

local function Shown(Value: unknown): string
	local Kind = typeof(Value)
	if Kind == "number" then return Round(Value :: number) end
	if Kind == "boolean" or Kind == "string" then return tostring(Value) end
	if Kind == "EnumItem" then return (Value :: EnumItem).Name end
	if Kind == "Vector3" then
		local Vector = Value :: Vector3
		return Round(Vector.X) .. ", " .. Round(Vector.Y) .. ", " .. Round(Vector.Z)
	end
	if Kind == "Color3" then
		local Colour = Value :: Color3
		return math.round(Colour.R * 255) .. ", " .. math.round(Colour.G * 255) .. ", " .. math.round(Colour.B * 255)
	end
	if Kind == "UDim2" then
		local Dim = Value :: UDim2
		return Round(Dim.X.Scale) .. ", " .. Round(Dim.X.Offset) .. ", " .. Round(Dim.Y.Scale) .. ", " .. Round(Dim.Y.Offset)
	end
	if Kind == "table" then
		local Count = 0
		for _ in Value :: Table do Count += 1 end
		return Count .. " entries"
	end
	if Kind == "nil" then return "removed" end
	return Kind
end

local function Quoted(Text: string): string
	local Safe = Text:gsub("\\", "\\\\")
	Safe = Safe:gsub("\"", "\\\"")
	Safe = Safe:gsub("\n", "\\n")
	return "\"" .. Safe .. "\""
end

local function Spell(Key: unknown): string
	if typeof(Key) == "number" then return "[" .. Key .. "]" end
	local Name = tostring(Key)
	if Name:match("^[%a_][%w_]*$") and not Reserved[Name] then return "." .. Name end
	return "[" .. Quoted(Name) .. "]"
end

local function Literal(Value: unknown): string?
	local Kind = typeof(Value)
	if Kind == "number" then
		local Number = Value :: number
		if Number ~= Number then return "0 / 0" end
		if Number == math.huge then return "math.huge" end
		if Number == -math.huge then return "-math.huge" end
		return tostring(Number)
	end
	if Kind == "string" then return Quoted(Value :: string) end
	if Kind == "boolean" or Kind == "nil" or Kind == "EnumItem" then return tostring(Value) end
	if Kind == "Vector3" then
		local Vector = Value :: Vector3
		return "Vector3.new(" .. tostring(Vector.X) .. ", " .. tostring(Vector.Y) .. ", " .. tostring(Vector.Z) .. ")"
	end
	if Kind == "Color3" then
		local Colour = Value :: Color3
		return "Color3.fromRGB(" .. math.round(Colour.R * 255) .. ", " .. math.round(Colour.G * 255) .. ", " .. math.round(Colour.B * 255) .. ")"
	end
	if Kind == "UDim2" then
		local Dim = Value :: UDim2
		return "UDim2.new(" .. tostring(Dim.X.Scale) .. ", " .. Dim.X.Offset .. ", " .. tostring(Dim.Y.Scale) .. ", " .. Dim.Y.Offset .. ")"
	end
	if Kind ~= "table" then return nil end
	local Target = Value :: Table
	local Items = {}
	local Count = #Target
	for Position = 1, Count do
		local Text = Literal(Target[Position])
		if not Text then return nil end
		table.insert(Items, Text)
	end
	local Named = {}
	for Key in Target do
		if not (typeof(Key) == "number" and Key >= 1 and Key <= Count and Key == math.floor(Key)) then table.insert(Named, Key) end
	end
	table.sort(Named, function(A, B) return tostring(A) < tostring(B) end)
	for _, Key in Named do
		local Text = Literal(Target[Key])
		if not Text then return nil end
		local Spelled = Spell(Key)
		table.insert(Items, (if Spelled:sub(1, 1) == "." then Spelled:sub(2) else Spelled) .. " = " .. Text)
	end
	return if #Items == 0 then "{}" else "{ " .. table.concat(Items, ", ") .. " }"
end

local function Numbers(Content: string, Count: number): { number }?
	local Read = {}
	for Piece in Content:gmatch("[^,%s]+") do
		local Number = tonumber(Piece)
		if not Number then return nil end
		table.insert(Read, Number)
	end
	return #Read == Count and Read or nil
end

local function Parse(Content: string, Like: unknown): (boolean, unknown, string?)
	local Kind = typeof(Like)
	if Kind == "number" then
		local Number = tonumber(Content)
		return Number ~= nil, Number, nil
	end
	if Kind == "string" then return true, Content, nil end
	if Kind == "Vector3" then
		local Read = Numbers(Content, 3)
		return Read ~= nil, Read and Vector3.new(Read[1], Read[2], Read[3]), nil
	end
	if Kind == "Color3" then
		local Trimmed = Content:match("^%s*(.-)%s*$") or ""
		if Trimmed:sub(1, 1) == "#" then
			local Ok, Colour = pcall(Color3.fromHex, Trimmed)
			return Ok, if Ok then Colour else nil, nil
		end
		local Read = Numbers(Content, 3)
		if not Read then return false, nil, nil end
		local Clamped = false
		for Position, Channel in Read do
			local Kept = math.clamp(Channel, 0, 255)
			if Kept ~= Channel then Clamped = true end
			Read[Position] = Kept
		end
		return true, Color3.fromRGB(Read[1], Read[2], Read[3]), if Clamped then "each channel runs 0 to 255, clamped" else nil
	end
	if Kind == "UDim2" then
		local Read = Numbers(Content, 4)
		return Read ~= nil, Read and UDim2.new(Read[1], Read[2], Read[3], Read[4]), nil
	end
	if Kind == "EnumItem" then
		local Ok, Item = pcall(function()
			return Enum[tostring((Like :: EnumItem).EnumType)][Content]
		end)
		return Ok and Item ~= nil, Item, nil
	end
	return false, nil, nil
end

local function Clear(Holder: Instance)
	for _, Child in Holder:GetChildren() do
		if Child:IsA("GuiObject") then Child:Destroy() end
	end
end

local function Clone(Template: string, Parent: Instance, Order: number): GuiObject
	local Copy = ((Templates :: Instance):FindFirstChild(Template) :: GuiObject):Clone()
	Copy.Name = Template .. Order
	Copy.LayoutOrder = Order
	local Height = Parent:GetAttribute("TouchHeight")
	if TouchOnly and typeof(Height) == "number" and Template ~= "Heading" and Template ~= "Section" then Copy.Size = UDim2.fromScale(1, Height) end
	Copy.Parent = Parent
	return Copy
end

local function Short(Name: string): string
	return (Name:gsub("(.)Module$", "%1"))
end

local function Group(Name: string): string
	local Main = Movement:FindFirstChild("MovementMain")
	for _, Folder in { "Core", "Extras", "Custom" } do
		local Children = Main and Main:FindFirstChild(Folder)
		if Children and Children:FindFirstChild(Name) then return Folder end
	end
	return "Kit"
end

local function Copy(Value: unknown): unknown
	if typeof(Value) ~= "table" then return Value end
	local Cloned = {}
	for Key, Entry in Value :: Table do Cloned[Key] = Copy(Entry) end
	return Cloned
end

local function Inside(Object: GuiObject, Position: Vector2): boolean
	local Offset = Position - Object.AbsolutePosition
	return Offset.X >= 0 and Offset.Y >= 0 and Offset.X <= Object.AbsoluteSize.X and Offset.Y <= Object.AbsoluteSize.Y
end

local function LastInputIs(Prefix: string): boolean
	return UserInputService:GetLastInputType().Name:sub(1, #Prefix) == Prefix
end

local function RootPlace(Name: string): Place
	return { Name = Name, Key = Name, Table = Whole[Name], Path = Name, Spelled = Name, Block = Name, Parent = nil }
end

local function ChildPlace(Parent: Place, Key: unknown): Place
	local Numbered = typeof(Key) == "number"
	local Name = if Numbered then "[" .. tostring(Key) .. "]" else tostring(Key)
	return { Name = Name, Key = Key, Table = Parent.Table[Key] :: Table, Path = Parent.Path .. (if Numbered then Name else "." .. Name), Spelled = Parent.Spelled .. Spell(Key), Block = Parent.Block, Parent = Parent }
end

local function SettingPath(Place: Place, Key: unknown): string
	return Place.Path .. (if typeof(Key) == "number" then "[" .. tostring(Key) .. "]" else "." .. tostring(Key))
end

local function StillInConfig(Place: Place): boolean
	local Parent = Place.Parent
	if not Parent then return Whole[Place.Name] == Place.Table end
	return Parent.Table[Place.Key] == Place.Table and StillInConfig(Parent)
end

local function Chain(Place: Place): { Place }
	local List = {}
	local Walk: Place? = Place
	while Walk do
		table.insert(List, 1, Walk)
		Walk = Walk.Parent
	end
	return List
end

local function CutTrail()
	for Position, Place in Trail do
		if StillInConfig(Place) then continue end
		for Cut = #Trail, Position, -1 do Trail[Cut] = nil end
		break
	end
	if #Trail == 0 and typeof(Whole[LastBlock]) == "table" then Trail = { RootPlace(LastBlock) } end
end

local function Same(A: Spot?, B: Spot?): boolean
	return A ~= nil and B ~= nil and A.Place.Table == B.Place.Table and A.Key == B.Key
end

local function RecordFor(Target: Table, Key: unknown): Change?
	local Held = Changes[Target]
	return Held and Held[Key]
end

local function Forget(Target: Table, Key: unknown)
	local Held = Changes[Target]
	if not Held or Held[Key] == nil then return end
	Held[Key] = nil
	CountMoved = true
	if next(Held) == nil then Changes[Target] = nil end
end

local function RecordOldValue(Place: Place, Key: unknown, Before: unknown)
	local Held = Changes[Place.Table]
	if not Held then
		Held = {}
		Changes[Place.Table] = Held
	end
	if Held[Key] then return end
	ChangeOrder += 1
	CountMoved = true
	Held[Key] = { Place = Place, Key = Key, Before = Before, Order = ChangeOrder }
end

local function AllChanges(): { Change }
	local List = {}
	for _, Held in Changes do
		for _, Record in Held do table.insert(List, Record) end
	end
	table.sort(List, function(A, B) return A.Order < B.Order end)
	return List
end

local function TouchedTables(): { [Table]: number }
	local Counts = {}
	for _, Held in Changes do
		for _, Record in Held do
			local Walk: Place? = Record.Place
			while Walk do
				Counts[Walk.Table] = (Counts[Walk.Table] or 0) + 1
				Walk = Walk.Parent
			end
		end
	end
	return Counts
end

local function WasValue(Place: Place, Key: unknown): (boolean, unknown)
	local Record = RecordFor(Place.Table, Key)
	if Record then return true, Record.Before end
	local List = RecordFor(Place.Table, WholeList)
	if List and (List.Before :: Table)[Key] ~= Place.Table[Key] then return true, (List.Before :: Table)[Key] end
	return false, nil
end

local function Changed(Place: Place, Key: unknown, Touched: { [Table]: number }): boolean
	local Value = Place.Table[Key]
	return WasValue(Place, Key) or (typeof(Value) == "table" and Touched[Value] ~= nil)
end

local function ChangeIsInside(Walk: Place?, Tables: { [Table]: boolean }): boolean
	while Walk do
		if Tables[Walk.Table] then return true end
		Walk = Walk.Parent
	end
	return false
end

local function ForgetInside(Target: Table)
	for _, Record in AllChanges() do
		if ChangeIsInside(Record.Place, { [Target] = true }) then Forget(Record.Place.Table, Record.Key) end
	end
end

local function Snapshot(Place: Place)
	if not RecordFor(Place.Table, WholeList) then RecordOldValue(Place, WholeList, table.clone(Place.Table)) end
end

local function ForgetIfRestored(Place: Place)
	local Record = RecordFor(Place.Table, WholeList)
	if not Record then return end
	local Before = Record.Before :: Table
	for Key, Value in Before do
		if Place.Table[Key] ~= Value then return end
	end
	for Key in Place.Table do
		if Before[Key] == nil then return end
	end
	Forget(Place.Table, WholeList)
end

local function LoadDocs(): Docs?
	if DocsLooked then return Docs end
	DocsLooked = true
	local Source = script:FindFirstChild("Docs")
	if not (Source and Source:IsA("ModuleScript")) then return nil end
	local Ok, Loaded = pcall(require, Source)
	if Ok and typeof(Loaded) == "table" and typeof(Loaded.Settings) == "table" then Docs = Loaded end
	return Docs
end

local function Lookup(Settings: { [string]: DocLine }, Path: string): DocLine?
	local Shape = Path:gsub("%[%d+%]", ".[]")
	local Hit = Settings[Path] or Settings[Shape]
	if Hit then return Hit end
	local Head, Last = Shape:match("^(.*)%.([^%.]+)$")
	if not Head then return nil end
	return Settings["*." .. Last] or Settings[Head .. ".*"]
end

local function IsKeyTable(Path: string): boolean
	local Known = KeyTables[Path]
	if Known == nil then
		Known = ConfigValidator.KeyChoices(Path) ~= nil
		KeyTables[Path] = Known
	end
	return Known
end

local function DocFor(Place: Place, Key: unknown): DocLine?
	local Loaded = LoadDocs()
	if not Loaded then return nil end
	local Hit = Lookup(Loaded.Settings, SettingPath(Place, Key))
	if Hit then return Hit end
	local Below = { if typeof(Key) == "number" then "[" .. tostring(Key) .. "]" else "." .. tostring(Key) }
	local Walk = Place
	while Walk.Parent do
		if IsKeyTable(Walk.Parent.Path) then return Lookup(Loaded.Settings, Walk.Block .. table.concat(Below)) end
		table.insert(Below, 1, if typeof(Walk.Key) == "number" then "[" .. tostring(Walk.Key) .. "]" else "." .. tostring(Walk.Key))
		Walk = Walk.Parent
	end
	return nil
end

local function BlockSummary(Name: string): string?
	local Loaded = LoadDocs()
	return Loaded and typeof(Loaded.Blocks) == "table" and Loaded.Blocks[Name] or nil
end

local function FillSearchText(Item: Entry)
	local Value, Doc = Item.Place.Table[Item.Key], DocFor(Item.Place, Item.Key)
	local Kind = typeof(Value)
	Item.ValueText = if Kind == "string" then ((Value :: string):match("[^%.]+$") or ""):lower() elseif Kind == "EnumItem" then (Value :: EnumItem).Name:lower() elseif Kind == "number" and tostring(Item.Key):match("Id$") then tostring(Value) else ""
	Item.PathValue = Item.PathText .. " " .. Item.ValueText
	Item.AllText = Item.PathValue .. " " .. (if Doc then Doc.Summary:lower() else "")
end

local function BuildIndex(): { Entry }
	local List = {}
	local function Visit(Place: Place, Depth: number)
		for Key, Value in Place.Table do
			local Path = SettingPath(Place, Key)
			local Item: Entry = { Place = Place, Key = Key, Path = Path, KeyText = tostring(Key):lower(), PathText = Path:lower(), ValueText = "", PathValue = "", AllText = "", Rank = 0 }
			FillSearchText(Item)
			table.insert(List, Item)
			if typeof(Value) == "table" and Depth < WalkDepth then Visit(ChildPlace(Place, Key), Depth + 1) end
		end
	end
	for Name, Block in Whole do
		if typeof(Block) == "table" then Visit(RootPlace(Name), 1) end
	end
	return List
end

local function AllIn(Text: string, Words: { string }): boolean
	for _, Word in Words do
		if not Text:find(Word, 1, true) then return false end
	end
	return true
end

local function Search(Text: string): { Entry }
	if not Index then Index = BuildIndex() end
	local Words = {}
	for Word in Text:lower():gmatch("%S+") do table.insert(Words, Word) end
	local Joined = table.concat(Words)
	local Matches = {}
	for _, Item in Index :: { Entry } do
		if not AllIn(Item.AllText, Words) then continue end
		Item.Rank = if Item.KeyText == Joined then 1 elseif AllIn(Item.KeyText, Words) then 2 elseif AllIn(Item.PathText, Words) then 3 elseif AllIn(Item.PathValue, Words) then 4 else 5
		table.insert(Matches, Item)
	end
	table.sort(Matches, function(A, B)
		if A.Rank ~= B.Rank then return A.Rank < B.Rank end
		if #A.Path ~= #B.Path then return #A.Path < #B.Path end
		return A.Path < B.Path
	end)
	return Matches
end

local function UpdateSearchText(Place: Place, Key: unknown)
	if not Index then return end
	for _, Item in Index do
		if Item.Place.Table == Place.Table and Item.Key == Key then FillSearchText(Item) end
	end
end

local function Clashes(Code: EnumItem, Spot: Spot): string?
	if not Index then Index = BuildIndex() end
	local Others = {}
	for _, Item in Index :: { Entry } do
		if Item.Place.Table[Item.Key] == Code and not Same(Item, Spot) then table.insert(Others, Item.Place.Spelled .. Spell(Item.Key)) end
		if #Others == 2 then break end
	end
	if #Others == 0 then return nil end
	return Code.Name .. " is also " .. table.concat(Others, " and ")
end

local function RangeText(Place: Place, Key: unknown): string?
	local Least, Most, ZeroAllowed = ConfigValidator.RangeFor(Place.Path, tostring(Key))
	if not (Least and Most) then return nil end
	return (if ZeroAllowed then "0 turns it off, otherwise " else "") .. Round(Least) .. " to " .. Round(Most)
end

local function Step(Base: number, WholeOnly: boolean): number
	if WholeOnly then return 1 end
	if Base == 0 then return 0.1 end
	if Base == math.floor(Base) and math.abs(Base) >= 5 then return 1 end
	if math.abs(Base) >= 1 then return 0.1 end
	return 0.01
end

local function InRange(Place: Place, Key: unknown, Value: number): (number, string?)
	local Current = Place.Table[Key] :: number
	if Value ~= Value or math.abs(Value) == math.huge then return Current, "not a usable number, kept " .. Round(Current) end
	local Least, Most, ZeroAllowed, WholeOnly = ConfigValidator.RangeFor(Place.Path, tostring(Key))
	local Kept = if WholeOnly then math.round(Value) else Value
	if Least and Kept < Least then
		if ZeroAllowed and Kept <= 0 then return 0, nil end
		return Least, "clamped to " .. Round(Least) .. ", it takes " .. (RangeText(Place, Key) or "more")
	end
	if Most and Kept > Most then return Most, "clamped to " .. Round(Most) .. ", it takes " .. (RangeText(Place, Key) or "less") end
	return Kept, nil
end

local function PaintToggle(Switch: TextButton, Value: boolean)
	local Knob = Switch:FindFirstChild("Knob") :: Frame
	Switch.BackgroundColor3 = Switch:GetAttribute(Value and "On" or "Off") :: Color3
	Knob.BackgroundColor3 = Switch:GetAttribute(Value and "KnobOn" or "KnobOff") :: Color3
	Knob.AnchorPoint = Vector2.new(Value and 1 or 0, 0.5)
	Knob.Position = Switch:GetAttribute(Value and "OnAt" or "OffAt") :: UDim2
end

local function PaintBlocks()
	local Counts = TouchedTables()
	for _, Child in Parts.Blocks:GetChildren() do
		if not Child:IsA("TextButton") then continue end
		local Name = Child:GetAttribute("Block") :: string
		local Picked = Name == LastBlock
		local Count = Child:FindFirstChild("Count") :: TextLabel
		local Mark = Child:FindFirstChild("Mark") :: Frame
		local Amount = Counts[Whole[Name]]
		Child.BackgroundColor3 = Child:GetAttribute(Picked and "Picked" or "Plain") :: Color3
		Mark.Visible = Picked
		Count.Visible = Amount ~= nil
		Count.Text = if Amount then tostring(Amount) else ""
	end
end

local function PaintArmed(Button: TextButton)
	Button.BackgroundColor3 = Button:GetAttribute(Armed and "Armed" or "Plain") :: Color3
	Button.TextColor3 = Button:GetAttribute(Armed and "ArmedText" or "PlainText") :: Color3
	Button.Text = if Armed then "Sure? " .. #AllChanges() else "Revert all"
end

local function PaintBar()
	local Count = #AllChanges()
	local Reload = Parts.Reload :: TextButton
	local Button = Parts.Changes :: TextButton
	Button.Text = if Count > 0 then "Changes " .. Count else "Changes"
	Reload.BackgroundColor3 = Reload:GetAttribute(Pending and "Pending" or "Idle") :: Color3
	Reload.TextColor3 = Reload:GetAttribute(Pending and "PendingText" or "IdleText") :: Color3
	CountMoved = false
end

local function PaintRow(Row: GuiObject, Place: Place, Key: unknown, Touched: { [Table]: number })
	local Value = Place.Table[Key]
	local Switch = Row:FindFirstChild("Toggle") :: TextButton?
	local Field = Row:FindFirstChild("Field") :: TextBox?
	local Pick = Row:FindFirstChild("Pick") :: TextButton?
	local Choose = Row:FindFirstChild("Choose") :: TextButton?
	local Open = Row:FindFirstChild("Open") :: TextButton?
	local Label = Row:FindFirstChild("Key") :: TextLabel
	local Dot = Row:FindFirstChild("Dot") :: Frame
	if Switch then PaintToggle(Switch, Value == true) end
	if Field and not Field:IsFocused() then Field.Text = Shown(Value) end
	if Pick and not (Capturing and Capturing.Button == Pick) then Pick.Text = Shown(Value) end
	if Choose then Choose.Text = Shown(Value) end
	if Open then Open.Text = Shown(Value) .. "  >" end
	local Swatch = Field and Field:FindFirstChild("Swatch") :: Frame?
	if Swatch then
		Swatch.Visible = typeof(Value) == "Color3"
		if typeof(Value) == "Color3" then Swatch.BackgroundColor3 = Value end
	end
	local IsPinned = Same(Spots[Row], Pinned)
	Row.BackgroundColor3 = Row:GetAttribute(IsPinned and "Picked" or "Plain") :: Color3
	Row.BackgroundTransparency = if IsPinned or Row:GetAttribute("Stripe") then 0 else 1
	Dot.Visible = Changed(Place, Key, Touched)
	local Name = Row:GetAttribute("Name") :: string
	local Was, Before = WasValue(Place, Key)
	Label.Text = if View == "Changes" and Was then Name .. "  was " .. Shown(Before) else Name
end

local function PaintRows()
	local Touched = TouchedTables()
	for Row, Spot in Spots do
		if Row.Parent then PaintRow(Row :: GuiObject, Spot.Place, Spot.Key, Touched) end
	end
end

local function PaintAround(Place: Place, Key: unknown)
	local Touched = TouchedTables()
	local Walk: Place?, Inner = Place, Key
	while Walk do
		local Row = Built[Walk.Table] and Built[Walk.Table][Inner]
		if Row and Row.Parent then PaintRow(Row, Walk, Inner, Touched) end
		Inner, Walk = Walk.Key, Walk.Parent
	end
end

local function FactsFor(Place: Place, Key: unknown): string
	local Value = Place.Table[Key]
	local Kind = typeof(Value)
	local Facts = {}
	if Kind == "number" then
		table.insert(Facts, RangeText(Place, Key) or "a number")
		local _, _, _, WholeOnly = ConfigValidator.RangeFor(Place.Path, tostring(Key))
		if WholeOnly then table.insert(Facts, "whole numbers") end
	elseif Kind == "Vector3" then
		table.insert(Facts, "type X, Y, Z")
	elseif Kind == "Color3" then
		table.insert(Facts, "type R, G, B from 0 to 255, or #F08214")
	elseif Kind == "UDim2" then
		table.insert(Facts, "type scale, offset, scale, offset")
	elseif Kind == "EnumItem" and (Value :: EnumItem).EnumType == Enum.KeyCode then
		table.insert(Facts, "click it, then press the new key, click it again to keep the old one")
	elseif Kind == "table" then
		local Touched = TouchedTables()[Value :: Table]
		table.insert(Facts, Shown(Value) .. (if Touched then ", " .. Touched .. " changed inside" else ""))
	elseif Kind == "string" then
		local Choices = ConfigValidator.Choices(Place.Path, Key)
		if Choices then table.insert(Facts, "one of " .. #Choices) end
	end
	local Doc = DocFor(Place, Key)
	if Doc and Doc.Accepts ~= "" then table.insert(Facts, Doc.Accepts) end
	local Was, Before = WasValue(Place, Key)
	if Was then table.insert(Facts, "was " .. Shown(Before)) end
	return table.concat(Facts, "   ")
end

local function ViewTitle(): string
	if View == "Search" then return if #Found == 0 then "No setting matches" else #Found .. " results" end
	if View == "Changes" then return #AllChanges() .. " changed this session" end
	if View == "Problems" then return if #Problems == 0 then "Config is clean" else #Problems .. " problems" end
	return ""
end

local function ShowInfo()
	if not Gui then return end
	local Setting = Parts.Setting :: TextLabel
	local Facts = Parts.Facts :: TextLabel
	local Summary = Parts.Summary :: TextLabel
	local More = Parts.More :: TextButton
	local Revert = Parts.Revert :: TextButton
	local Target = Hovered or Pinned
	if Target and not StillInConfig(Target.Place) then Target = nil end
	local Picked = Target ~= nil and (Hovered == nil or Same(Hovered, Pinned))
	if Target then
		local Warning = if Picked then Notice else nil
		local Doc = DocFor(Target.Place, Target.Key)
		Setting.Text = Target.Place.Spelled .. Spell(Target.Key)
		Facts.Text = Warning or FactsFor(Target.Place, Target.Key)
		Facts.TextColor3 = Facts:GetAttribute(if Warning then "Warn" else "Plain") :: Color3
		Summary.Text = if Doc then Doc.Summary else ""
		Revert.Visible = Picked and Changed(Target.Place, Target.Key, TouchedTables())
		More.Visible = Picked and Doc ~= nil and (#Summary.Text > LongSummary or not Summary.TextFits)
		return
	end
	local Here = Trail[#Trail]
	Revert.Visible, More.Visible = false, false
	Facts.TextColor3 = Facts:GetAttribute("Plain") :: Color3
	if View ~= "Browse" or not Here then
		Setting.Text = ViewTitle()
		Facts.Text = if View == "Changes" then "Export writes them as lines to paste into MovementConfig" else ""
		Summary.Text = ""
		return
	end
	local Total, Touched = 0, TouchedTables()
	local Edited = 0
	for Key in Here.Table do
		Total += 1
		if Changed(Here, Key, Touched) then Edited += 1 end
	end
	Setting.Text = Here.Spelled
	Facts.Text = Total .. " settings, " .. Edited .. " changed"
	Summary.Text = if #Trail == 1 then BlockSummary(Here.Name) or "" else ""
end

local function Pin(Spot: Spot)
	if not Same(Spot, Pinned) then
		Pinned, Notice = Spot, nil
		PaintRows()
	end
	ShowInfo()
end

local function Hover(Spot: Spot?)
	if Spot then
		local Pointer = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
		if not LastInputIs("Mouse") or (Parts.Picker :: GuiObject).Visible or not Inside(Parts.Rows :: GuiObject, Pointer) then return end
	end
	if Same(Spot, Hovered) or (Spot == nil and Hovered == nil) then return end
	Hovered = Spot
	ShowInfo()
end

local function ShowOutput(Heading: string, Content: string, Highlight: boolean?)
	local Output = Parts.Output :: Frame
	local Body = Parts.Text :: TextBox
	local Title = Parts.Heading :: TextLabel
	local Scroll = Parts.Scroll :: ScrollingFrame
	local Rows = Parts.Rows :: ScrollingFrame
	Title.Text = Heading
	Body.Text = Content
	Scroll.CanvasPosition = Vector2.zero
	Output.Visible = true
	Rows.Visible = false
	if not Highlight then return end
	Body:CaptureFocus()
	task.defer(function()
		if not Body:IsFocused() then return end
		Body.SelectionStart = 1
		Body.CursorPosition = #Body.Text + 1
	end)
end

local function HideOutput()
	local Output = Parts.Output :: Frame
	local Rows = Parts.Rows :: ScrollingFrame
	Output.Visible = false
	Rows.Visible = true
end

local function ClosePicker()
	local Picker = Parts.Picker :: ScrollingFrame
	local Anchor = PickerAnchor
	local Selected = GuiService.SelectedObject
	Picker.Visible = false
	PickerAnchor = nil
	if Anchor and Anchor.Parent and Selected and Selected:IsDescendantOf(Picker) then GuiService.SelectedObject = Anchor end
end

local function OpenPicker(Anchor: GuiObject, Names: { string }, Current: string, OnPick: (string) -> ())
	if #Names == 0 then return end
	local Picker = Parts.Picker :: ScrollingFrame
	local Window = Parts.Window :: Frame
	local Match: GuiObject? = nil
	Clear(Picker)
	local Visible = math.min(#Names, PickerRows)
	for Order, Name in Names do
		local Option = Clone("Option", Picker, Order) :: TextButton
		Option.Text = Name
		Option.Size = UDim2.fromScale(1, 1 / Visible)
		Option.Activated:Connect(function()
			ClosePicker()
			OnPick(Name)
		end)
		if Name == Current or not Match then Match = Option end
	end
	local Full = Picker:GetAttribute("Full") :: UDim2
	local Width, Height = Full.X.Scale, Full.Y.Scale * Visible / PickerRows
	local Corner = (Anchor.AbsolutePosition + Vector2.new(0, Anchor.AbsoluteSize.Y) - Window.AbsolutePosition) / Window.AbsoluteSize
	Picker.Size = UDim2.fromScale(Width, Height)
	Picker.Position = UDim2.fromScale(math.clamp(Corner.X, 0, 1 - Width), math.clamp(Corner.Y, 0, 1 - Height))
	Picker.CanvasPosition = Vector2.zero
	Picker.Visible = true
	PickerAnchor = Anchor
	if LastInputIs("Gamepad") then task.defer(function() if Picker.Visible then GuiService.SelectedObject = Match end end) end
end

local function RememberScroll()
	local Here = Trail[#Trail]
	if View == "Browse" and Here and Gui then Scrolls[Here.Table] = (Parts.Rows :: ScrollingFrame).CanvasPosition end
end

local function RecheckProblems()
	if View ~= "Problems" or Repeating then return end
	local Fresh = ConfigValidator.Validate(MovementConfig, true)
	if table.concat(Fresh, "\n") == table.concat(Problems, "\n") then return end
	Problems = Fresh
	Render()
end

local function Rebuild()
	Pending = true
	Index = nil
	Render()
	RecheckProblems()
end

local function Refresh(Place: Place, Key: unknown, Structural: boolean)
	if Structural then
		Rebuild()
		return
	end
	local WasPending = Pending
	Pending = true
	UpdateSearchText(Place, Key)
	if not Gui then return end
	local Row = Built[Place.Table] and Built[Place.Table][Key]
	if Row and Row.Parent then
		PaintAround(Place, Key)
		if CountMoved or not WasPending then
			PaintBlocks()
			PaintBar()
		end
		ShowInfo()
	else
		Render()
	end
	RecheckProblems()
end

local function Write(Place: Place, Key: unknown, Value: unknown)
	local Target = Place.Table
	local Old = Target[Key]
	if Old == Value then return end
	if typeof(Key) == "number" then
		Snapshot(Place)
		Target[Key] = Value
		ForgetIfRestored(Place)
	else
		local Record = RecordFor(Target, Key)
		if not Record then
			RecordOldValue(Place, Key, Old)
		elseif Record.Before == Value then
			Forget(Target, Key)
			if typeof(Old) == "table" then ForgetInside(Old) end
		end
		Target[Key] = Value
	end
	Refresh(Place, Key, typeof(Key) == "number" or Old == nil or Value == nil or typeof(Old) == "table" or typeof(Value) == "table")
end

local function Append(Place: Place, Value: unknown)
	Snapshot(Place)
	Place.Table[#Place.Table + 1] = Value
	ForgetIfRestored(Place)
	Refresh(Place, #Place.Table, true)
end

local function AddKey(Place: Place, Name: string)
	local Sample = Place.Table.Default
	if Sample == nil then
		local First = nil
		for Key in Place.Table do
			if First == nil or tostring(Key) < tostring(First) then First = Key end
		end
		Sample = if First == nil then {} else Place.Table[First]
	end
	Write(Place, Name, Copy(Sample))
end

local function Remove(Place: Place, Key: number)
	local List = Place.Table
	local Gone = List[Key]
	Snapshot(Place)
	for Position = Key, #List do List[Position] = List[Position + 1] end
	ForgetIfRestored(Place)
	local Kept = RecordFor(List, WholeList)
	if typeof(Gone) == "table" and not (Kept and table.find(Kept.Before :: { unknown }, Gone)) then ForgetInside(Gone) end
	Refresh(Place, Key, true)
end

local function Revert(Target: Table, Key: unknown)
	local Record = RecordFor(Target, Key)
	local Contained: { [Table]: boolean } = {}
	if Record and Key == WholeList then
		local Before = Record.Before :: Table
		table.clear(Target)
		for Position, Value in Before do Target[Position] = Value end
		Contained[Target] = true
	elseif Record then
		local Live = Target[Key]
		Target[Key] = Record.Before
		if typeof(Live) == "table" then Contained[Live] = true end
		if typeof(Record.Before) == "table" then Contained[Record.Before :: Table] = true end
	elseif typeof(Target[Key]) == "table" then
		Contained[Target[Key] :: Table] = true
	end
	if Record then Forget(Target, Key) end
	for _, Other in AllChanges() do
		if RecordFor(Other.Place.Table, Other.Key) == Other and ChangeIsInside(Other.Place, Contained) then Revert(Other.Place.Table, Other.Key) end
	end
end

local function RevertSpot(Spot: Spot)
	local Place, Key = Spot.Place, Spot.Key
	local Old = Place.Table[Key]
	local WholeRevert = not RecordFor(Place.Table, Key) and RecordFor(Place.Table, WholeList) ~= nil and (WasValue(Place, Key))
	Revert(Place.Table, if WholeRevert then WholeList else Key)
	local New = Place.Table[Key]
	local Structural = WholeRevert or typeof(Key) == "number" or Old == nil or New == nil or typeof(Old) == "table" or typeof(New) == "table"
	Notice = nil
	if View == "Changes" and not Structural then
		Pending = true
		UpdateSearchText(Place, Key)
		Render()
		return
	end
	Refresh(Place, Key, Structural)
end

local function ResetChanges()
	for _, Record in AllChanges() do
		if RecordFor(Record.Place.Table, Record.Key) == Record then Revert(Record.Place.Table, Record.Key) end
	end
	table.clear(Changes)
	CountMoved = true
	Notice = nil
	Rebuild()
end

local function StopCapture()
	local Caught = Capturing
	if not Caught then return end
	Capturing, Notice = nil, nil
	if Caught.Button.Parent then Caught.Button.Text = Shown(Caught.Spot.Place.Table[Caught.Spot.Key]) end
	ShowInfo()
end

local function StartCapture(Spot: Spot, Button: TextButton)
	local Name = tostring(Spot.Key)
	local Wants = if typeof(Spot.Key) == "number" then "Any" elseif Name:match("ConsoleInput$") or Name:match("Button$") then "Gamepad" else "Keyboard"
	Capturing = { Spot = Spot, Button = Button, Wants = Wants, Since = os.clock() }
	Button.Text = if Wants == "Gamepad" then "press a pad button" else "press a key"
	Notice = "press the new " .. (if Wants == "Gamepad" then "button" else "key") .. ", click it again to keep " .. Shown(Spot.Place.Table[Spot.Key])
	ShowInfo()
end

local function Heading(Rows: Instance, Order: number, Text: string, Tone: string, OnClick: (() -> ())?): TextButton
	local Made = Clone("Heading", Rows, Order) :: TextButton
	local Arrow = Made:FindFirstChild("Arrow") :: TextLabel
	Made.Text = Text
	Made.TextColor3 = Made:GetAttribute(Tone) :: Color3
	Made.Selectable = OnClick ~= nil
	Arrow.Visible = OnClick ~= nil
	if OnClick then Made.Activated:Connect(OnClick) end
	return Made
end

local function ChainText(Place: Place): string
	local Names = {}
	for _, Link in Chain(Place) do table.insert(Names, if Link.Parent then Link.Name else Short(Link.Name)) end
	if #Names > 4 then Names = { Names[1], "...", Names[#Names - 1], Names[#Names] } end
	return table.concat(Names, "  >  ")
end

local function WireStep(Button: TextButton, Spot: Spot, Direction: number)
	local function Nudge(Times: number)
		if not Same(Spot, Pinned) then Pin(Spot) end
		local Current = Spot.Place.Table[Spot.Key]
		if typeof(Current) ~= "number" then return end
		local Record = RecordFor(Spot.Place.Table, Spot.Key)
		local Base = if Record and typeof(Record.Before) == "number" then Record.Before :: number else Current
		local _, _, _, WholeOnly = ConfigValidator.RangeFor(Spot.Place.Path, tostring(Spot.Key))
		local Next = Current + Step(Base, WholeOnly) * Direction * Times
		if Next ~= math.floor(Next) then Next = math.round(Next * 1000) / 1000 end
		local Kept, Reason = InRange(Spot.Place, Spot.Key, Next)
		Notice = if Kept == Current then (if Direction > 0 then "at the maximum " else "at the minimum ") .. Round(Kept) else Reason
		Write(Spot.Place, Spot.Key, Kept)
		if Kept == Current then ShowInfo() end
	end
	Button.InputBegan:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton2 then
			Nudge(10)
			return
		end
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		Nudge(1)
		HoldToken += 1
		local Mine = HoldToken
		task.delay(HoldDelay, function()
			local Stepped = false
			while Mine == HoldToken and Button.Parent and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				Repeating = true
				Nudge(1)
				Repeating = false
				Stepped = true
				task.wait(HoldRate)
			end
			if Stepped then RecheckProblems() end
		end)
	end)
	Button.InputEnded:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then HoldToken += 1 end
	end)
	Button.Activated:Connect(function(Input: InputObject?)
		if Input and Input.UserInputType.Name:sub(1, 5) == "Mouse" then return end
		Nudge(1)
	end)
end

local function WireField(Row: GuiObject, Field: TextBox, Spot: Spot, Numeric: boolean)
	Field.Focused:Connect(function()
		Pin(Spot)
		task.defer(function()
			if not Field:IsFocused() then return end
			Field.SelectionStart = 1
			Field.CursorPosition = #Field.Text + 1
		end)
	end)
	Field.FocusLost:Connect(function()
		local Current = Spot.Place.Table[Spot.Key]
		if Field.Text ~= Shown(Current) then
			local Like = if Numeric then 0 else Current
			local Ok, Parsed, Reason = Parse(Field.Text, Like)
			if Ok and Numeric then Parsed, Reason = InRange(Spot.Place, Spot.Key, Parsed :: number) end
			Notice = if Ok then Reason else (if Numeric then "not a number, kept " else "does not read as that type, kept ") .. Shown(Current)
			if Ok then Write(Spot.Place, Spot.Key, Parsed) end
		end
		if Row.Parent then PaintRow(Row, Spot.Place, Spot.Key, TouchedTables()) end
		ShowInfo()
	end)
end

local function EnumNames(Value: EnumItem): { string }
	local Names = {}
	for _, Item in Value.EnumType:GetEnumItems() do table.insert(Names, Item.Name) end
	return Names
end

local function BuildRow(Rows: Instance, Order: number, Place: Place, Key: unknown, Drop: (() -> ())?, Stripe: boolean): GuiObject
	local Value = Place.Table[Key]
	local Kind = typeof(Value)
	local Name = if typeof(Key) == "number" then "[" .. Key .. "]" else tostring(Key)
	local Spot: Spot = { Place = Place, Key = Key }
	local Choices = if Kind == "string" then ConfigValidator.Choices(Place.Path, Key) else nil
	local Row: GuiObject
	if typeof(Value) == "table" then
		local Tag = Value.Effect or Value.Name
		if typeof(Tag) == "string" then Name ..= "  " .. Tag end
	end
	if Kind == "boolean" then
		Row = Clone("ToggleRow", Rows, Order)
		local Switch = Row:FindFirstChild("Toggle") :: TextButton
		Switch.Activated:Connect(function()
			Pin(Spot)
			Write(Place, Key, not (Place.Table[Key] == true))
		end)
	elseif Kind == "number" and not Name:match("Id$") then
		Row = Clone("NumberRow", Rows, Order)
		WireStep(Row:FindFirstChild("Minus") :: TextButton, Spot, -1)
		WireStep(Row:FindFirstChild("Plus") :: TextButton, Spot, 1)
		WireField(Row, Row:FindFirstChild("Field") :: TextBox, Spot, true)
	elseif Kind == "EnumItem" and (Value :: EnumItem).EnumType == Enum.KeyCode then
		Row = Clone("KeyRow", Rows, Order)
		local Pick = Row:FindFirstChild("Pick") :: TextButton
		Pick.Activated:Connect(function()
			Pin(Spot)
			local Again = Capturing ~= nil and Capturing.Button == Pick
			StopCapture()
			if not Again then StartCapture(Spot, Pick) end
		end)
	elseif Kind == "EnumItem" or Choices then
		Row = Clone("ChoiceRow", Rows, Order)
		local Choose = Row:FindFirstChild("Choose") :: TextButton
		local Names = if Choices then Choices else EnumNames(Value :: EnumItem)
		Choose.Activated:Connect(function()
			Pin(Spot)
			OpenPicker(Choose, Names, Shown(Place.Table[Key]), function(Picked: string)
				local Ok, Parsed = Parse(Picked, Place.Table[Key])
				if Ok then Write(Place, Key, Parsed) end
			end)
		end)
	elseif Kind == "string" or Kind == "Vector3" or Kind == "Color3" or Kind == "UDim2" or Kind == "number" then
		Row = Clone("TextRow", Rows, Order)
		WireField(Row, Row:FindFirstChild("Field") :: TextBox, Spot, Kind == "number")
	elseif Kind == "table" then
		Row = Clone("TableRow", Rows, Order)
		local Open = Row:FindFirstChild("Open") :: TextButton
		Open.Activated:Connect(function()
			Pin(Spot)
			OpenTable(Place, Key)
		end)
	else
		Row = Clone("InfoRow", Rows, Order)
		local Note = Row:FindFirstChild("Note") :: TextLabel
		Note.Text = if Kind == "nil" then "removed" else Kind
	end
	local Label = Row:FindFirstChild("Key") :: TextLabel
	local Hit = Row:FindFirstChild("Hit") :: TextButton
	Row:SetAttribute("Name", Name)
	Row:SetAttribute("Stripe", Stripe)
	Spots[Row] = Spot
	Built[Place.Table] = Built[Place.Table] or {}
	Built[Place.Table][Key] = Row
	Hit.Activated:Connect(function() Pin(Spot) end)
	Row.MouseEnter:Connect(function() Hover(Spot) end)
	if Drop then
		local Remover = Row:FindFirstChild("Remove") :: TextButton
		local Shifted = Label:GetAttribute("Shifted") :: UDim2
		Remover.Visible = true
		Label.Size = UDim2.fromScale(Label.Size.X.Scale - (Shifted.X.Scale - Label.Position.X.Scale), Label.Size.Y.Scale)
		Label.Position = Shifted
		Remover.Activated:Connect(Drop)
	end
	return Row
end

local function RenderSpots(Rows: Instance, List: { Spot }, Order: number, Dropping: boolean): number
	local Groups, Orders = {}, {}
	for _, Spot in List do
		local Target = Spot.Place.Table
		if not Groups[Target] then
			Groups[Target] = {}
			table.insert(Orders, Spot.Place)
		end
		table.insert(Groups[Target], Spot)
	end
	for _, Place in Orders do
		local Members = Groups[Place.Table]
		local First = Members[1]
		Order += 1
		Heading(Rows, Order, ChainText(Place), "Link", function() JumpTo(Place, First.Key) end)
		for Position, Spot in Members do
			if Built[Spot.Place.Table] and Built[Spot.Place.Table][Spot.Key] then continue end
			Order += 1
			BuildRow(Rows, Order, Spot.Place, Spot.Key, if Dropping then function() RevertSpot(Spot) end else nil, Position % 2 == 1)
		end
	end
	return Order
end

local function ActionRow(Rows: Instance, Order: number, Title: string, Action: string, OnAction: () -> (), Undo: boolean)
	local Row = Clone("ActionRow", Rows, Order)
	local Export = Row:FindFirstChild("Export") :: TextButton
	local RevertAll = Row:FindFirstChild("RevertAll") :: TextButton
	local Label = Row:FindFirstChild("Key") :: TextLabel
	Label.Text = Title
	Export.Text = Action
	Export.Activated:Connect(OnAction)
	RevertAll.Visible = Undo
	PaintArmed(RevertAll)
	RevertAll.Activated:Connect(function() ArmOrRevert(RevertAll) end)
end

local function KindOf(Place: Place, Key: unknown, Value: unknown): number
	local Name = tostring(Key)
	local Kind = typeof(Value)
	if Name:sub(1, 11) == "DoublePress" or (Kind == "EnumItem" and (Value :: EnumItem).EnumType == Enum.KeyCode) then return 3 end
	if Kind == "boolean" then return 1 end
	if Kind == "EnumItem" or (Kind == "string" and ConfigValidator.Choices(Place.Path, Key)) then return 2 end
	if Name:match("SoundId$") then return 6 end
	if Name:match("AnimationId$") then return 7 end
	if Kind == "number" then return 4 end
	if Kind == "string" or Kind == "Vector3" or Kind == "Color3" or Kind == "UDim2" then return 5 end
	if Kind ~= "table" then return 10 end
	if Name:match("Vfx$") or EffectTables[Name] then return 8 end
	if Name == "R6" or Name == "R15" or Name:match("Animations$") or Name:match("AnimationSpeed$") then return 7 end
	if Name:match("Sounds$") or Name:match("SFX$") then return 6 end
	return 9
end

local function RenderBrowse(Rows: Instance)
	local Here = Trail[#Trail]
	local Target = Here.Table
	local Keys = {}
	for Key in Target do table.insert(Keys, Key) end
	local Choices = ConfigValidator.KeyChoices(Here.Path)
	local Listed = #Keys == #Target
	local Grouped = not Choices and not Listed and #Keys > MinGrouped
	local Kinds, Counts = {}, {}
	for _, Key in Keys do
		Kinds[Key] = KindOf(Here, Key, Target[Key])
		Counts[Kinds[Key]] = (Counts[Kinds[Key]] or 0) + 1
	end
	table.sort(Keys, function(A, B)
		if Grouped and Kinds[A] ~= Kinds[B] then return Kinds[A] < Kinds[B] end
		if Grouped and (A == "Enabled" or A == "Mode") ~= (B == "Enabled" or B == "Mode") then return A == "Enabled" or A == "Mode" end
		local TableA, TableB = typeof(Target[A]) == "table", typeof(Target[B]) == "table"
		if not Grouped and TableA ~= TableB then return TableB end
		if typeof(A) == typeof(B) then return A < B end
		return typeof(A) == "number"
	end)
	local Order, Stripe, Last = 0, 0, nil
	for _, Key in Keys do
		if Grouped and Kinds[Key] ~= Last then
			Last = Kinds[Key]
			Order += 1
			Stripe = 0
			Heading(Rows, Order, KindTitles[Last]:upper() .. "  " .. Counts[Last], "Plain", nil)
		end
		Order += 1
		Stripe += 1
		local Drop = if typeof(Key) == "number" then function() Remove(Here, Key :: number) end elseif Choices then function() Write(Here, Key, nil) end else nil
		BuildRow(Rows, Order, Here, Key, Drop, Stripe % 2 == 0)
	end
	local Words = if Listed then ConfigValidator.Choices(Here.Path, #Target + 1) else nil
	if not (Choices or Listed) then return end
	local Add = Clone("AddRow", Rows, Order + 1)
	local Button = Add:FindFirstChild("Add") :: TextButton
	Button.Activated:Connect(function()
		local Offered = Choices or Words
		if not Offered then
			Append(Here, if #Target == 0 then ConfigValidator.Blank(Here.Path) or "" else Copy(Target[#Target]))
			return
		end
		local Unused = {}
		for _, Name in Offered do
			if (Choices and Target[Name] == nil) or (not Choices and not table.find(Target, Name)) then table.insert(Unused, Name) end
		end
		OpenPicker(Button, Unused, "", function(Name: string)
			if Choices then AddKey(Here, Name) else Append(Here, Name) end
		end)
	end)
end

local function RenderSearch(Rows: Instance)
	Found = Search(Query)
	local Picked = {}
	for Position = 1, math.min(#Found, MostResults) do table.insert(Picked, { Place = Found[Position].Place, Key = Found[Position].Key }) end
	local Order = RenderSpots(Rows, Picked, 0, false)
	if #Found > MostResults then Heading(Rows, Order + 1, (#Found - MostResults) .. " more, add a word", "Plain", nil) end
end

local function RenderChanges(Rows: Instance)
	ActionRow(Rows, 1, #AllChanges() .. " changed this session", "Export", function() ExportChanges() end, true)
	local Records = AllChanges()
	local List, Seen = {}, {}
	table.sort(Records, function(A, B) return A.Place.Spelled .. tostring(A.Key) < B.Place.Spelled .. tostring(B.Key) end)
	for _, Record in Records do
		local Place, Key = Record.Place, Record.Key
		if not StillInConfig(Place) then continue end
		if Key == WholeList then
			if not Place.Parent then continue end
			Place, Key = Place.Parent, Place.Key
		end
		Seen[Place.Table] = Seen[Place.Table] or {}
		if Seen[Place.Table][Key] then continue end
		Seen[Place.Table][Key] = true
		table.insert(List, { Place = Place, Key = Key })
	end
	if #List == 0 then
		Heading(Rows, 2, "Nothing changed yet", "Plain", nil)
		return
	end
	RenderSpots(Rows, List, 1, true)
end

local function Resolve(Problem: string): Spot?
	local Path = Problem:match("^[%w_%.%[%]]+")
	if not Path then return nil end
	Path = Path:gsub("[%.:]+$", "")
	local Pieces = {}
	for Piece in Path:gsub("%[(%d+)%]", ".%1"):gmatch("[^%.]+") do table.insert(Pieces, Piece) end
	if Pieces[1] == "Config" then table.remove(Pieces, 1) end
	if typeof(Whole[Pieces[1]]) ~= "table" or #Pieces == 1 then return nil end
	local function Walk(Place: Place, From: number): Spot?
		for Last = #Pieces, From, -1 do
			local Joined = table.concat(Pieces, ".", From, Last)
			local Key: unknown = if Place.Table[Joined] == nil and tonumber(Joined) then tonumber(Joined) else Joined
			local Value = Place.Table[Key]
			if Value == nil then continue end
			if Last == #Pieces then return { Place = Place, Key = Key } end
			if typeof(Value) == "table" then
				local Deeper = Walk(ChildPlace(Place, Key), Last + 1)
				if Deeper then return Deeper end
			end
		end
		return nil
	end
	return Walk(RootPlace(Pieces[1]), 2)
end

local function RenderProblems(Rows: Instance)
	ActionRow(Rows, 1, ViewTitle(), "Show as text", function() ShowOutput(ViewTitle(), table.concat(Problems, "\n")) end, false)
	local Order = 1
	for _, Problem in Problems do
		local Spot = Resolve(Problem)
		Order += 1
		Heading(Rows, Order, Problem, "Warn", if Spot then function() JumpTo(Spot.Place, Spot.Key) end else nil)
		if not Spot or (Built[Spot.Place.Table] and Built[Spot.Place.Table][Spot.Key]) then continue end
		Order += 1
		BuildRow(Rows, Order, Spot.Place, Spot.Key, nil, false)
	end
end

local function GoBackTo(Depth: number)
	if Depth < 1 or Depth >= #Trail then return end
	RememberScroll()
	for Cut = #Trail, Depth + 1, -1 do Trail[Cut] = nil end
	HideOutput()
	Show()
end

local function PaintCrumbs()
	local Crumbs = Parts.Crumbs
	local Up = Parts.Up :: TextButton
	local Path = Parts.Path :: TextLabel
	for _, Child in Crumbs:GetChildren() do
		if Child:IsA("TextButton") and Child.Name:match("^Crumb%d+$") then Child:Destroy() end
	end
	if View ~= "Browse" then
		Path.Visible = true
		Path.Text = ViewTitle()
		Up.Visible = true
		return
	end
	Path.Visible = false
	Up.Visible = #Trail > 1
	local Picked = {}
	if #Trail <= MostCrumbs then
		for Depth = 1, #Trail do table.insert(Picked, Depth) end
	else
		Picked = { 1, 0, #Trail - 2, #Trail - 1, #Trail }
	end
	for Order, Depth in Picked do
		local Crumb = Clone("Crumb", Crumbs, Order + 1) :: TextButton
		local Target = if Depth == 0 then #Trail - 3 else Depth
		Crumb.Text = if Depth == 0 then "..." elseif Depth == 1 then Short(Trail[1].Name) else Trail[Depth].Name
		Crumb.TextColor3 = Crumb:GetAttribute(if Depth == #Trail then "Here" else "Plain") :: Color3
		Crumb.Activated:Connect(function() GoBackTo(Target) end)
	end
end

local function MainControl(Row: Instance): GuiObject?
	for _, Name in Controls do
		local Control = Row:FindFirstChild(Name)
		if Control and Control:IsA("GuiObject") and Control.Visible then return Control end
	end
	if Row:IsA("GuiButton") and Row.Selectable then return Row end
	return nil
end

local function LinkSelection(Rows: Instance): GuiObject?
	local Linked = {}
	for _, Child in Rows:GetChildren() do
		local Main = MainControl(Child)
		if Main then table.insert(Linked, { Row = Child :: GuiObject, Main = Main }) end
	end
	table.sort(Linked, function(A, B) return A.Row.LayoutOrder < B.Row.LayoutOrder end)
	for Position, Item in Linked do
		local Above, Below = Linked[Position - 1], Linked[Position + 1]
		local Members = Item.Row:GetDescendants()
		table.insert(Members, Item.Row)
		for _, Control in Members do
			if not (Control:IsA("GuiButton") or Control:IsA("TextBox")) or not Control.Selectable then continue end
			Control.NextSelectionUp = if Above then Above.Main else nil
			Control.NextSelectionDown = if Below then Below.Main else nil
		end
	end
	return if Linked[1] then Linked[1].Main else nil
end

function Render()
	if Rendering or not Gui then return end
	Rendering = true
	local Rows = Parts.Rows :: ScrollingFrame
	local Scroll = Rows.CanvasPosition
	local Selected = GuiService.SelectedObject
	local Kept: Spot?, KeptName: string? = nil, nil
	if Selected and Selected:IsDescendantOf(Rows) then
		local Walk: Instance? = Selected
		while Walk and Walk ~= Rows and not Spots[Walk] do Walk = Walk.Parent end
		if Walk and Spots[Walk] then Kept, KeptName = Spots[Walk], Selected.Name end
	end
	ClosePicker()
	Clear(Rows)
	table.clear(Built)
	table.clear(Spots)
	CutTrail()
	if View == "Search" then
		RenderSearch(Rows)
	elseif View == "Changes" then
		RenderChanges(Rows)
	elseif View == "Problems" then
		RenderProblems(Rows)
	elseif Trail[#Trail] then
		RenderBrowse(Rows)
	end
	PaintRows()
	PaintCrumbs()
	PaintBlocks()
	PaintBar()
	RowsLinked = LastInputIs("Gamepad")
	if RowsLinked then LinkSelection(Rows) end
	Rows.CanvasPosition = Scroll
	if Kept then
		local Row = Built[Kept.Place.Table] and Built[Kept.Place.Table][Kept.Key]
		local Control = Row and Row:FindFirstChild(KeptName, true)
		if Control then GuiService.SelectedObject = Control :: GuiObject end
	end
	ShowInfo()
	Rendering = false
end

function Show(Scroll: Vector2?)
	if not Gui then return end
	Render()
	local Rows = Parts.Rows :: ScrollingFrame
	local Here = Trail[#Trail]
	local Target = Scroll or (View == "Browse" and Here and Scrolls[Here.Table]) or Vector2.zero
	Rows.CanvasPosition = Target
	RunService.Heartbeat:Once(function()
		if Rows.Parent then Rows.CanvasPosition = Target end
	end)
end

local function ClearSearch()
	local Box = Parts.Search :: TextBox
	local Cross = Parts.ClearSearch :: GuiObject
	if Box.Text ~= "" then Box.Text = "" end
	Cross.Visible = false
end

local function SwitchView(Name: string)
	RememberScroll()
	View, Armed = Name, false
	ClearSearch()
	HideOutput()
	Show(if Name == "Browse" then nil else Vector2.zero)
end

local function GoTo(Target: Place)
	RememberScroll()
	if Trail[1] then Trails[Trail[1].Name] = table.clone(Trail) end
	Trail = Chain(Target)
	LastBlock = Target.Block
	View = "Browse"
	ClearSearch()
	HideOutput()
end

function OpenTable(Place: Place, Key: unknown)
	local Child = ChildPlace(Place, Key)
	if View ~= "Browse" then
		GoTo(Child)
		Show(Vector2.zero)
		return
	end
	RememberScroll()
	table.insert(Trail, Child)
	Show()
end

function JumpTo(Place: Place, Key: unknown)
	if not StillInConfig(Place) then return end
	GoTo(Place)
	Render()
	Pin({ Place = Place, Key = Key })
	local Rows = Parts.Rows :: ScrollingFrame
	local Row = Built[Place.Table] and Built[Place.Table][Key]
	if not Row then return end
	local Offset = 0
	for _, Child in Rows:GetChildren() do
		if Child:IsA("GuiObject") and Child.LayoutOrder < Row.LayoutOrder then Offset += Child.Size.Y.Scale * Rows.AbsoluteSize.Y end
	end
	local Target = Vector2.new(0, math.max(0, Offset - Rows.AbsoluteSize.Y / 3))
	Rows.CanvasPosition = Target
	RunService.Heartbeat:Once(function()
		if Rows.Parent then Rows.CanvasPosition = Target end
	end)
end

local function Open(Name: string)
	if typeof(Whole[Name]) ~= "table" then return end
	local Here = View == "Browse" and Trail[1] ~= nil and Trail[1].Name == Name
	GoTo(RootPlace(Name))
	local Saved = Trails[Name]
	if not Here and Saved and StillInConfig(Saved[#Saved]) then Trail = table.clone(Saved) end
	Show()
end

local function Back(): boolean
	if (Parts.Picker :: GuiObject).Visible then
		ClosePicker()
	elseif (Parts.Output :: GuiObject).Visible then
		HideOutput()
	elseif View ~= "Browse" then
		SwitchView("Browse")
	elseif #Trail > 1 then
		GoBackTo(#Trail - 1)
	else
		return false
	end
	return true
end

local function ApplySearch(Quiet: boolean?)
	local Trimmed = (Parts.Search :: TextBox).Text:match("^%s*(.-)%s*$") or ""
	if #Trimmed >= 2 then
		if View == "Search" and Trimmed == Query and not (Parts.Output :: GuiObject).Visible then return end
		if View ~= "Search" and not Quiet then RememberScroll() end
		View, Query = "Search", Trimmed
		HideOutput()
		if not Quiet then Show(Vector2.zero) end
	elseif View == "Search" then
		View = "Browse"
		HideOutput()
		if not Quiet then Show() end
	end
end

function ExportChanges()
	local Records = AllChanges()
	local Touched = TouchedTables()
	local Covered: { [Table]: boolean } = {}
	for _, Record in Records do
		if not StillInConfig(Record.Place) then continue end
		if Record.Key == WholeList then
			Covered[Record.Place.Table] = true
			continue
		end
		local Live = Record.Place.Table[Record.Key]
		if typeof(Live) == "table" then Covered[Live] = true end
		if typeof(Record.Before) == "table" then Covered[Record.Before :: Table] = true end
	end
	local Lines = {}
	local function Emit(Path: string, Value: unknown)
		local Text = Literal(Value)
		if Text then
			table.insert(Lines, Path .. " = " .. Text)
		elseif typeof(Value) == "table" then
			for Key, Entry in Value :: Table do
				if typeof(Entry) ~= "function" then Emit(Path .. Spell(Key), Entry) end
			end
		end
	end
	for _, Record in Records do
		if not StillInConfig(Record.Place) or ChangeIsInside(if Record.Key == WholeList then Record.Place.Parent else Record.Place, Covered) then continue end
		if Record.Key ~= WholeList then
			Emit("Config." .. Record.Place.Spelled .. Spell(Record.Key), Record.Place.Table[Record.Key])
			continue
		end
		local Live, Before = Record.Place.Table, Record.Before :: Table
		local Path = "Config." .. Record.Place.Spelled
		if Literal(Live) then
			Emit(Path, Live)
			continue
		end
		for Key, Value in Live do
			if typeof(Value) == "function" then continue end
			if Before[Key] ~= Value or RecordFor(Live, Key) ~= nil or (typeof(Value) == "table" and Touched[Value] ~= nil) then Emit(Path .. Spell(Key), Value) end
		end
		for Key in Before do
			if Live[Key] == nil then table.insert(Lines, Path .. Spell(Key) .. " = nil") end
		end
	end
	table.sort(Lines)
	if #Lines == 0 then
		ShowOutput("Nothing to export yet", "")
		return
	end
	local Text = table.concat(Lines, "\n")
	Api.Log.Info("paste these above return Config in MovementConfig\n" .. Text)
	ShowOutput(#Lines .. " lines, Ctrl+C copies them, paste them above return Config in MovementConfig", Text, true)
end

function ArmOrRevert(Button: TextButton)
	if #AllChanges() == 0 then return end
	if not Armed then
		Armed = true
		ArmToken += 1
		local Mine = ArmToken
		PaintArmed(Button)
		task.delay(ArmTime, function()
			if Mine ~= ArmToken or not Armed then return end
			Armed = false
			if Button.Parent then PaintArmed(Button) end
		end)
		return
	end
	Armed = false
	ResetChanges()
	ReloadKit()
end

function ReloadKit()
	Problems = ConfigValidator.Validate(MovementConfig)
	Pending, Armed = false, false
	if #Problems > 0 then SwitchView("Problems") end
	task.defer(function()
		local Main = require(Movement.MovementMain) :: { Reload: () -> () }
		Main.Reload()
	end)
end

local function Pressed(Input: InputObject)
	local Kind = Input.UserInputType
	local Clicked = Kind == Enum.UserInputType.MouseButton1 or Kind == Enum.UserInputType.Touch
	local Position = Vector2.new(Input.Position.X, Input.Position.Y)
	local Picker = Parts.Picker :: ScrollingFrame
	if Picker.Visible and Clicked and not Inside(Picker, Position) then ClosePicker() end
	local Caught = Capturing
	if not Caught then return end
	if Clicked then
		if not (Caught.Button.Parent and Inside(Caught.Button, Position)) then StopCapture() end
		return
	end
	if os.clock() - Caught.Since < CaptureGrace or UserInputService:GetFocusedTextBox() then return end
	local Pad = Kind.Name:sub(1, 7) == "Gamepad"
	local Code = Input.KeyCode
	if Kind ~= Enum.UserInputType.Keyboard and not Pad then return end
	if Code.Name == "Unknown" or Code == Enum.KeyCode.Thumbstick1 or Code == Enum.KeyCode.Thumbstick2 then return end
	if Code == Enum.KeyCode.Escape then
		StopCapture()
		return
	end
	if (Caught.Wants == "Keyboard" and Pad) or (Caught.Wants == "Gamepad" and not Pad) then return end
	StopCapture()
	Notice = Clashes(Code, Caught.Spot)
	Write(Caught.Spot.Place, Caught.Spot.Key, Code)
	ShowInfo()
end

local function BackAction(_, State: Enum.UserInputState): Enum.ContextActionResult
	if State ~= Enum.UserInputState.Begin then return if PassedBack then Enum.ContextActionResult.Pass else Enum.ContextActionResult.Sink end
	PassedBack = false
	if Capturing then return Enum.ContextActionResult.Sink end
	if Back() then return Enum.ContextActionResult.Sink end
	PassedBack = true
	return Enum.ContextActionResult.Pass
end

local function WatchInput()
	local Screen = Gui :: ScreenGui
	local Rows = Parts.Rows
	Listening = UserInputService.InputBegan:Connect(Pressed)
	Focusing = UserInputService.TextBoxFocused:Connect(StopCapture)
	Selecting = GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		local Selected = GuiService.SelectedObject
		if not RowsLinked and Selected and Selected:IsDescendantOf(Rows) then
			RowsLinked = true
			LinkSelection(Rows)
		end
		local Walk: Instance? = Selected
		while Walk and Walk ~= Screen and not Spots[Walk] do Walk = Walk.Parent end
		if Walk and Spots[Walk] then Pin(Spots[Walk]) end
	end)
	ContextActionService:BindActionAtPriority("ConfigMenuBack", BackAction, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonB)
end

local function StopWatchingInput()
	for _, Link in { Listening, Focusing, Selecting } do
		if Link then Link:Disconnect() end
	end
	Listening, Focusing, Selecting = nil, nil, nil
	ContextActionService:UnbindAction("ConfigMenuBack")
	local Selected = GuiService.SelectedObject
	if Gui and Selected and Selected:IsDescendantOf(Gui) then GuiService.SelectedObject = nil end
end

local function FitScale()
	local Window = Parts.Window :: Frame
	local Sizer = Parts.UIScale :: UIScale
	local Shape = Window:FindFirstChildOfClass("UIAspectRatioConstraint")
	local Area = (Gui :: ScreenGui).AbsoluteSize
	local Scale = Api.Config.Scale
	if Area.X > 0 and Area.Y > 0 then
		local Width, Height = Window.Size.X.Scale * Area.X, Window.Size.Y.Scale * Area.Y
		if Shape and Width / Height > Shape.AspectRatio then Width = Height * Shape.AspectRatio elseif Shape then Height = Width / Shape.AspectRatio end
		Scale = math.min(Scale, 0.98 * Area.X / Width, 0.98 * Area.Y / Height)
	end
	Sizer.Scale = Scale
end

local function Toggle()
	local Screen = Gui :: ScreenGui
	Screen.Enabled = not Screen.Enabled
	ClosePicker()
	if Screen.Enabled then
		FitScale()
		WatchInput()
		if #Trail == 0 then Open(LastBlock) else Show() end
		if LastInputIs("Gamepad") then task.defer(function() GuiService.SelectedObject = LinkSelection(Parts.Rows) end) end
		return
	end
	StopWatchingInput()
	StopCapture()
	RememberScroll()
	Clear(Parts.Rows)
	table.clear(Built)
	table.clear(Spots)
	HoldToken += 1
	Armed = false
	Hovered = nil
	if Pending then ReloadKit() end
end

local function Clamped(Middle: Vector2, Window: Frame, Screen: ScreenGui): Vector2
	local Half, Area = Window.AbsoluteSize / 2, Screen.AbsoluteSize
	return Vector2.new(math.clamp(Middle.X, Half.X, math.max(Half.X, Area.X - Half.X)), math.clamp(Middle.Y, Half.Y, math.max(Half.Y, Area.Y - Half.Y)))
end

local function StopDragging()
	if Dragging then Dragging:Disconnect() end
	if Releasing then Releasing:Disconnect() end
	Dragging, Releasing = nil, nil
end

local function Drag(Window: Frame, Input: InputObject)
	StopDragging()
	local Grip = Vector2.new(Input.Position.X, Input.Position.Y) - Window.AbsolutePosition
	local ByMouse = Input.UserInputType == Enum.UserInputType.MouseButton1
	Dragging = UserInputService.InputChanged:Connect(function(Moved: InputObject)
		if Moved.UserInputType ~= Enum.UserInputType.MouseMovement and Moved.UserInputType ~= Enum.UserInputType.Touch then return end
		if ByMouse and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			StopDragging()
			return
		end
		local Screen = Gui :: ScreenGui
		local Middle = Clamped(Vector2.new(Moved.Position.X, Moved.Position.Y) - Grip + Window.AbsoluteSize / 2 - Screen.AbsolutePosition, Window, Screen)
		Window.Position = UDim2.fromScale(Middle.X / Screen.AbsoluteSize.X, Middle.Y / Screen.AbsoluteSize.Y)
	end)
	Releasing = UserInputService.InputEnded:Connect(function(Released: InputObject)
		if Released.UserInputType == Enum.UserInputType.MouseButton1 or Released.UserInputType == Enum.UserInputType.Touch then StopDragging() end
	end)
end

local function BuildBlocks()
	local Blocks = Parts.Blocks
	Clear(Blocks)
	local Grouped = { Kit = {}, Core = {}, Extras = {}, Custom = {} }
	for Name, Block in Whole do
		if typeof(Block) == "table" then table.insert(Grouped[Group(Name)], Name) end
	end
	local Order = 0
	for _, Title in { "Kit", "Core", "Extras", "Custom" } do
		local Names = Grouped[Title]
		if #Names == 0 then continue end
		table.sort(Names)
		Order += 1
		local Section = Clone("Section", Blocks, Order) :: TextLabel
		Section.Text = Title:upper()
		for _, Name in Names do
			Order += 1
			local Pick = Clone("Block", Blocks, Order) :: TextButton
			Pick.Text = Short(Name)
			Pick:SetAttribute("Block", Name)
			Pick.Activated:Connect(function() Open(Name) end)
		end
	end
end

local function Wire()
	local Search = Parts.Search :: TextBox
	local Window = Parts.Window :: Frame
	Lifetime:Add((Parts.Close :: TextButton).Activated:Connect(Toggle))
	Lifetime:Add((Parts.Changes :: TextButton).Activated:Connect(function() SwitchView(if View == "Changes" then "Browse" else "Changes") end))
	Lifetime:Add((Parts.Validate :: TextButton).Activated:Connect(function()
		Problems = ConfigValidator.Validate(MovementConfig)
		SwitchView("Problems")
	end))
	Lifetime:Add((Parts.Reload :: TextButton).Activated:Connect(ReloadKit))
	Lifetime:Add((Parts.Up :: TextButton).Activated:Connect(Back))
	Lifetime:Add((Parts.Dismiss :: TextButton).Activated:Connect(HideOutput))
	Lifetime:Add((Parts.Select :: TextButton).Activated:Connect(function() ShowOutput((Parts.Heading :: TextLabel).Text, (Parts.Text :: TextBox).Text, true) end))
	Lifetime:Add((Parts.More :: TextButton).Activated:Connect(function() ShowOutput((Parts.Setting :: TextLabel).Text, (Parts.Facts :: TextLabel).Text .. "\n\n" .. (Parts.Summary :: TextLabel).Text) end))
	Lifetime:Add((Parts.Revert :: TextButton).Activated:Connect(function()
		if Pinned then RevertSpot(Pinned) end
	end))
	Lifetime:Add((Parts.Info :: Frame).MouseEnter:Connect(function() Hover(nil) end))
	Lifetime:Add((Parts.Rows :: ScrollingFrame).MouseLeave:Connect(function() Hover(nil) end))
	Lifetime:Add((Parts.ClearSearch :: TextButton).Activated:Connect(ClearSearch))
	Lifetime:Add(Search:GetPropertyChangedSignal("Text"):Connect(function()
		local Cross = Parts.ClearSearch :: GuiObject
		SearchToken += 1
		local Mine = SearchToken
		Cross.Visible = Search.Text ~= ""
		task.delay(SearchDelay, function()
			if Mine == SearchToken and Gui then ApplySearch(not Gui.Enabled) end
		end)
	end))
	Lifetime:Add(Search.FocusLost:Connect(function(EnterPressed: boolean)
		if not EnterPressed then return end
		SearchToken += 1
		ApplySearch()
		local First = Found[1]
		if View == "Search" and First then JumpTo(First.Place, First.Key) end
	end))
	Lifetime:Add((Parts.Title :: Frame).InputBegan:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then Drag(Window, Input) end
	end))
	local WithButton = UserInputService.TouchEnabled and MovementConfig.TouchButtons.Enabled
	ContextActionUtility:BindAction("ConfigMenu", function(_, State: Enum.UserInputState)
		if State == Enum.UserInputState.Begin and not Capturing and not UserInputService:GetFocusedTextBox() then Toggle() end
	end, WithButton, Api.Config.OpenKey, Api.Config.OpenButton)
	if WithButton then ContextActionUtility:SetTitle("ConfigMenu", "CONFIG") end
	Lifetime:Add(function() ContextActionUtility:UnbindAction("ConfigMenu") end)
end

local function CopyWindow(PlayerGui: Instance): ScreenGui?
	local Window = script:FindFirstChild("Window") :: ScreenGui?
	if not Window then return nil end
	local Copied = Window:Clone()
	Copied.Name = "MovementConfigMenu"
	Copied.ResetOnSpawn = false
	Copied.Parent = PlayerGui
	return Copied
end

local function Missing(Screen: ScreenGui): string?
	if not Templates then return "ConfigMenu has no Templates" end
	for _, Name in WindowParts do
		local Element = Screen:FindFirstChild(Name, true)
		if not Element then return "MovementConfigMenu has no " .. Name end
		Parts[Name] = Element
	end
	for _, Name in TemplateNames do
		if not Templates:FindFirstChild(Name) then return "ConfigMenu > Templates has no " .. Name end
	end
	return nil
end

function ConfigMenu:Init(NewApi: MovementTypes.Api<Settings>)
	if NewApi.Config.StudioOnly and not RunService:IsStudio() then return end
	self:Cleanup()
	Api = NewApi
	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local Screen = (PlayerGui:FindFirstChild("MovementConfigMenu") :: ScreenGui?) or CopyWindow(PlayerGui)
	if not Screen then
		Api.Log.Warn("StarterGui has no MovementConfigMenu, insert the config menu again from the plugin")
		return
	end
	local Gap = Missing(Screen)
	if Gap then
		table.clear(Parts)
		Api.Log.Warn(Gap .. ", insert the config menu again from the plugin")
		return
	end
	local Window = Parts.Window :: Frame
	Gui = Screen
	table.clear(Built)
	table.clear(Spots)
	Capturing, Pinned, Hovered, Notice = nil, nil, nil, nil
	Rendering = false
	TouchOnly = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	if TouchOnly then Window.Size = Window:GetAttribute("TouchSize") :: UDim2 end
	BuildBlocks()
	Wire()
	Screen.Enabled = false
	if WasOpen then Toggle() end
end

function ConfigMenu:Toggle()
	if Gui then Toggle() end
end

function ConfigMenu:Cleanup()
	Lifetime:Clean()
	StopWatchingInput()
	StopDragging()
	StopCapture()
	HoldToken += 1
	if Gui then
		WasOpen = Gui.Enabled
		Gui.Enabled = false
		Gui = nil
	end
	table.clear(Parts)
	Api = nil
end

return ConfigMenu
]==]
