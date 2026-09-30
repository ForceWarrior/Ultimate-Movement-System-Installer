--// [Modules]
local Theme = require(script.Parent.Theme)
local Settings = require(script.Parent.Settings)
local Content = require(script.Parent.Content)
local Requirements = require(script.Parent.Requirements)

--// [Variables]
local MainScreen = {}

--// [Do not go past this point]

MainScreen.__index = MainScreen

local function AccentButton(Text, Width)
	local Button = Theme.Button(Text, Width or 150, 36, true)
	Button.TextSize = Theme.Size(14)
	return Button
end

local function QuietButton(Text, Width)
	return Theme.Button(Text, Width or 100, 30, false)
end

function MainScreen.New(Parent, PluginHandle)
	local self = setmetatable({}, MainScreen)

	self.ReadyEvent = Instance.new("BindableEvent")
	self.Ready = self.ReadyEvent.Event

	local Landing = Instance.new("Frame")
	Landing.Name = "Landing"
	Landing.Size = UDim2.fromScale(1, 1)
	Landing.BackgroundTransparency = 1
	Landing.Parent = Parent
	self.Landing = Landing

	local Heading = Theme.Label(Content.Landing.Heading, 22, Theme.Text, Theme.TitleFont)
	Heading.Position = UDim2.new(0, 0, 0.26, 0)
	Heading.Size = UDim2.new(1, 0, 0, 28)
	Heading.TextXAlignment = Enum.TextXAlignment.Center
	Heading.Parent = Landing

	local Subheading = Theme.Label(Content.Landing.Subheading, 13, Theme.MutedText)
	Subheading.Position = UDim2.new(0, 0, 0.26, 30)
	Subheading.Size = UDim2.new(1, 0, 0, 18)
	Subheading.TextXAlignment = Enum.TextXAlignment.Center
	Subheading.Parent = Landing

	local VersionLabel = Theme.Label(Content.Landing.VersionLabel, 13, Theme.MutedText)
	VersionLabel.Position = UDim2.new(0.5, -84, 0.6, -70)
	VersionLabel.Size = UDim2.new(0, 168, 0, 18)
	VersionLabel.TextXAlignment = Enum.TextXAlignment.Center
	VersionLabel.Parent = Landing

	local Picker = Theme.Dropdown(Landing, Parent, "", 168, 30, 60)
	Picker.Button.Position = UDim2.new(0.5, -84, 0.6, -48)
	local Options = {}
	for Index, Entry in Settings.Versions do
		Options[Index] = { Label = Entry.Label, Value = Entry.Value }
	end
	Picker.SetOptions(Options)
	local Saved = PluginHandle and PluginHandle:GetSetting("KitVersion")
	local Current = Settings.Choose(Saved) or Settings.Version
	for Index, Entry in Settings.Versions do
		if Entry == Current then
			Picker.Select(Index)
		end
	end
	Picker.OnPick = function(_, Item)
		Settings.Choose(Item.Value)
		if PluginHandle then
			PluginHandle:SetSetting("KitVersion", Item.Value)
		end
	end

	local Start = AccentButton(Content.Landing.Button, 168)
	Start.Position = UDim2.new(0.5, -84, 0.6, 0)
	Start.Parent = Landing

	local Gate = Instance.new("Frame")
	Gate.Name = "Gate"
	Gate.Size = UDim2.fromScale(1, 1)
	Gate.BackgroundTransparency = 1
	Gate.Visible = false
	Gate.Parent = Parent
	self.Gate = Gate

	local Column = Instance.new("Frame")
	Column.Name = "Column"
	Column.AnchorPoint = Vector2.new(0.5, 0)
	Column.Position = UDim2.fromScale(0.5, 0)
	Column.Size = UDim2.fromScale(1, 1)
	Column.BackgroundTransparency = 1
	Column.Parent = Gate
	Theme.Padding(Column, 20)

	local ColumnCap = Instance.new("UISizeConstraint")
	ColumnCap.MaxSize = Vector2.new(900, math.huge)
	ColumnCap.Parent = Column

	local ColumnLayout = Instance.new("UIListLayout")
	ColumnLayout.Padding = UDim.new(0, 8)
	ColumnLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ColumnLayout.Parent = Column

	local GateHeading = Theme.Label(Content.Gate.Heading, 16, Theme.Text, Theme.TitleFont)
	GateHeading.LayoutOrder = 1
	GateHeading.Size = UDim2.new(1, 0, 0, 24)
	GateHeading.Parent = Column

	local List = Instance.new("ScrollingFrame")
	List.Name = "List"
	List.LayoutOrder = 2
	List.Size = UDim2.new(1, 0, 0, 0)
	List.BackgroundTransparency = 1
	List.BorderSizePixel = 0
	List.ScrollBarThickness = 4
	List.ScrollBarImageColor3 = Theme.MutedText
	List.CanvasSize = UDim2.new()
	List.AutomaticCanvasSize = Enum.AutomaticSize.Y
	List.Parent = Column
	self.List = List

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 8)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = List

	local function FitList()
		local Rows = Layout.AbsoluteContentSize.Y
		local PageHeight = Gate.AbsoluteSize.Y / Theme.ScaleOf(Gate)
		local Cap = PageHeight > 0 and math.floor(PageHeight * 0.6) or Rows
		List.Size = UDim2.new(1, 0, 0, math.min(Rows, Cap))
	end
	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(FitList)
	Gate:GetPropertyChangedSignal("AbsoluteSize"):Connect(FitList)
	FitList()

	local Buttons = Instance.new("Frame")
	Buttons.Name = "Buttons"
	Buttons.LayoutOrder = 3
	Buttons.Size = UDim2.new(1, 0, 0, 38)
	Buttons.BackgroundTransparency = 1
	Buttons.Parent = Column

	local Recheck = AccentButton(Content.Gate.Recheck, 136)
	Recheck.Position = UDim2.new(0, 0, 0, 1)
	Recheck.Parent = Buttons

	local Back = QuietButton(Content.Gate.Back, 88)
	Back.Position = UDim2.new(0, 146, 0, 4)
	Back.Parent = Buttons

	Start.Activated:Connect(function()
		self:Evaluate()
	end)
	Recheck.Activated:Connect(function()
		self:Evaluate()
	end)
	Back.Activated:Connect(function()
		self:Reset()
	end)

	return self
end

function MainScreen:BuildRow(Index, Entry)
	local Row = Instance.new("Frame")
	Row.Name = "Row" .. Index
	Row.LayoutOrder = Index
	Row.Size = UDim2.new(1, -6, 0, 60)
	Row.BackgroundColor3 = Theme.Panel
	Row.BorderSizePixel = 0
	Row.Parent = self.List
	Theme.Stroke(Row)

	local Number = Theme.Label(Index .. ".", 15, Theme.Accent, Theme.TitleFont)
	Number.Position = UDim2.new(0, 12, 0, 9)
	Number.Size = UDim2.fromOffset(22, 20)
	Number.Parent = Row

	local Title = Theme.Label(Entry.Title, 13, Theme.Text, Theme.MediumFont)
	Title.Position = UDim2.new(0, 36, 0, 9)
	Title.Size = UDim2.new(1, -150, 0, 18)
	Title.Parent = Row

	local Detail = Theme.Label(Entry.Detail, 12, Theme.MutedText)
	Detail.Position = UDim2.new(0, 36, 0, 28)
	Detail.Size = UDim2.new(1, -150, 0, 26)
	Detail.TextWrapped = true
	Detail.TextYAlignment = Enum.TextYAlignment.Top
	Detail.Parent = Row

	if Entry.Manual then
		local Tick = QuietButton(Content.Gate.Acknowledge, 96)
		Tick.Position = UDim2.new(1, -104, 0, 16)
		Tick.Parent = Row
		Tick.Activated:Connect(function()
			Requirements.AcknowledgeBeta(true)
			self:Evaluate()
		end)
	end
end

function MainScreen:Evaluate()
	local Failed = Requirements.Blocking(Requirements.Check())

	if #Failed == 0 then
		self.Gate.Visible = false
		self.Landing.Visible = false
		self.ReadyEvent:Fire()
		return
	end

	for _, Child in self.List:GetChildren() do
		if Child:IsA("Frame") then
			Child:Destroy()
		end
	end
	for Index, Entry in Failed do
		self:BuildRow(Index, Entry)
	end

	self.Landing.Visible = false
	self.Gate.Visible = true
end

function MainScreen:Reset()
	self.Gate.Visible = false
	self.Landing.Visible = true
end

function MainScreen:Destroy()
	self.ReadyEvent:Destroy()
	self.Landing:Destroy()
	self.Gate:Destroy()
end

return MainScreen
