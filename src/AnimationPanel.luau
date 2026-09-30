--// [Modules]
local Theme = require(script.Parent.Theme)
local Content = require(script.Parent.Content)
local ConfigScanner = require(script.Parent.ConfigScanner)
local AnimationMatcher = require(script.Parent.AnimationMatcher)
local AnimationUploader = require(script.Parent.AnimationUploader)

--// [Variables]
local AnimationPanel = {}

--// [Do not go past this point]

AnimationPanel.__index = AnimationPanel

local RowHeight = 24

local function IsEmpty(Raw)
	return not tostring(Raw):match("[1-9]")
end

local function Pretty(Raw)
	if Raw:sub(1, 1) == "{" then
		local Parts = {}
		for Number in Raw:gmatch("%d+") do
			table.insert(Parts, Number)
		end
		return table.concat(Parts, ", ")
	end
	return Raw
end

local function Chip(Text, Width, Accent)
	return Theme.Button(Text, Width, 24, Accent)
end

local function Tick(Parent, Indent)
	local Box = Instance.new("TextButton")
	Box.Size = UDim2.fromOffset(14, 14)
	Box.Position = UDim2.new(0, Indent, 0, 4)
	Box.BackgroundColor3 = Theme.Background
	Box.BorderSizePixel = 0
	Box.Text = ""
	Box.AutoButtonColor = false
	Box.Parent = Parent
	Theme.Stroke(Box, Theme.Border)

	local Fill = Instance.new("Frame")
	Fill.Size = UDim2.fromScale(0.6, 0.6)
	Fill.Position = UDim2.fromScale(0.2, 0.2)
	Fill.BackgroundColor3 = Theme.Accent
	Fill.BorderSizePixel = 0
	Fill.Visible = false
	Fill.Parent = Box
	return Box, Fill
end

local ManualKey = "UMSInstaller_ManualClips"

local ConfirmColumns = {
	{ Title = "LINE", Left = 0, Right = 0.07 },
	{ Title = "CONFIG SLOT", Left = 0.07, Right = 0.54 },
	{ Title = "CURRENT ID", Left = 0.54, Right = 0.76 },
	{ Title = "REPLACED BY", Left = 0.76, Right = 1 },
}

function AnimationPanel.New(Parent, PluginHandle, Page)
	local self = setmetatable({}, AnimationPanel)
	self.Plugin = PluginHandle
	self.Page = Page or Parent
	self.Cancelled = false
	self.Selected = {}
	self.Expanded = {}
	self.Rows = {}
	self.Matches = {}
	self.Manual = (PluginHandle and PluginHandle:GetSetting(ManualKey)) or {}
	if typeof(self.Manual) ~= "table" then
		self.Manual = {}
	end
	self.Destinations = AnimationUploader.Destinations()
	self.Busy = false

	local Root = Instance.new("Frame")
	Root.Name = "Animations"
	Root.Size = UDim2.new(1, -10, 1, 0)
	Root.BackgroundTransparency = 1
	Root.Parent = Parent
	self.Root = Root

	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.new(1, 0, 0, 26)
	Bar.BackgroundTransparency = 1
	Bar.Parent = Root

	local BarLayout = Instance.new("UIListLayout")
	BarLayout.FillDirection = Enum.FillDirection.Horizontal
	BarLayout.Padding = UDim.new(0, 6)
	BarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	BarLayout.Parent = Bar

	local Picks = {
		{ Content.Animations.SelectAll, 52, function()
			for _, Row in self.Rows do
				self.Selected[Row.Path] = true
			end
		end },
		{ Content.Animations.SelectUnfilled, 86, function()
			table.clear(self.Selected)
			for _, Row in self.Rows do
				if tonumber(Row.Raw) == 0 then
					self.Selected[Row.Path] = true
				end
			end
		end },
		{ Content.Animations.Clear, 52, function()
			table.clear(self.Selected)
		end },
	}
	for Index, Entry in Picks do
		local Button = Chip(Entry[1], Entry[2])
		Button.LayoutOrder = Index
		Button.Parent = Bar
		Button.Activated:Connect(function()
			if self.Busy then return end
			Entry[3]()
			self:Render()
		end)
	end

	local Action = Instance.new("Frame")
	Action.Position = UDim2.new(0, 0, 0, 30)
	Action.Size = UDim2.new(1, 0, 0, 26)
	Action.BackgroundTransparency = 1
	Action.Parent = Root

	local ActionLayout = Instance.new("UIListLayout")
	ActionLayout.FillDirection = Enum.FillDirection.Horizontal
	ActionLayout.Padding = UDim.new(0, 6)
	ActionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ActionLayout.Parent = Action

	local Location = Theme.Dropdown(Action, self.Page, Content.Animations.UploadLocation, 240, 24)
	Location.Button.LayoutOrder = 1
	self.Location = Location

	local Upload = Chip(Content.Animations.Upload, 120, true)
	Upload.LayoutOrder = 2
	Upload.Parent = Action
	self.Upload = Upload
	Upload.Activated:Connect(function()
		if self.Busy or not self.Location.Get() then
			return
		end
		self:AskThenUpload()
	end)

	local Options = {}
	for Index, Entry in self.Destinations do
		Options[Index] = { Label = Entry.Label, Short = Entry.Short or Entry.Label }
	end
	Location.SetOptions(Options)
	Location.OnPick = function()
		self:Render()
	end

	local Summary = Theme.Label("", 12, Theme.MutedText)
	Summary.Position = UDim2.new(0, 0, 0, 58)
	Summary.Size = UDim2.new(1, 0, 0, 16)
	Summary.Parent = Root
	self.Summary = Summary

	local Header = Instance.new("Frame")
	Header.Position = UDim2.new(0, 0, 0, 78)
	Header.Size = UDim2.new(1, 0, 0, 16)
	Header.BackgroundTransparency = 1
	Header.Parent = Root

	local Columns = {
		{ Content.Animations.ColumnLine, UDim2.new(0, 60, 0, 0), UDim2.fromOffset(36, 16) },
		{ Content.Animations.ColumnKey, UDim2.new(0, 98, 0, 0), UDim2.new(0.36, -98, 1, 0) },
		{ Content.Animations.ColumnClip, UDim2.new(0.36, 0, 0, 0), UDim2.new(0.3, -6, 1, 0) },
		{ Content.Animations.ColumnId, UDim2.new(0.66, 0, 0, 0), UDim2.new(0.34, -8, 1, 0) },
	}
	for _, Column in Columns do
		local Label = Theme.Label(Column[1], 10, Theme.MutedText, Theme.TitleFont)
		Label.Position = Column[2]
		Label.Size = Column[3]
		Label.Parent = Header
	end

	local Shell, Pane = Theme.Group(Root, Content.Animations.TreeTitle)
	Shell.Position = UDim2.new(0, 0, 0, 108)
	Shell.Size = UDim2.new(1, 0, 1, -108)

	local Scroll = Instance.new("ScrollingFrame")
	Scroll.Size = UDim2.fromScale(1, 1)
	Scroll.BackgroundTransparency = 1
	Scroll.BorderSizePixel = 0
	Scroll.ScrollBarThickness = 4
	Scroll.ScrollBarImageColor3 = Theme.MutedText
	Scroll.CanvasSize = UDim2.new()
	Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Scroll.Parent = Pane
	self.Scroll = Scroll

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Scroll

	self.Notice = Theme.Notice(self.Page, 70, Content.Animations.Ok)
	self:BuildConfirm(self.Page)
	self:BuildProgress(self.Page)
	return self
end

function AnimationPanel:BuildProgress(Parent)
	local Veil = Instance.new("TextButton")
	Veil.Name = "Progress"
	Veil.Size = UDim2.fromScale(1, 1)
	Veil.BackgroundColor3 = Theme.Background
	Veil.BackgroundTransparency = 0.02
	Veil.BorderSizePixel = 0
	Veil.Text = ""
	Veil.AutoButtonColor = false
	Veil.Modal = true
	Veil.Visible = false
	Veil.ZIndex = 50
	Veil.Parent = Parent
	self.ProgressVeil = Veil

	local Heading = Theme.Label(Content.Animations.Working, 15, Theme.Text, Theme.TitleFont)
	Heading.Position = UDim2.new(0, 0, 0.32, 0)
	Heading.Size = UDim2.new(1, 0, 0, 24)
	Heading.TextXAlignment = Enum.TextXAlignment.Center
	Heading.ZIndex = 51
	Heading.Parent = Veil

	local Detail = Theme.Label("", 13, Theme.Text)
	Detail.Position = UDim2.new(0, 0, 0.32, 28)
	Detail.Size = UDim2.new(1, 0, 0, 20)
	Detail.TextXAlignment = Enum.TextXAlignment.Center
	Detail.ZIndex = 51
	Detail.Parent = Veil
	self.ProgressDetail = Detail

	local Track = Instance.new("Frame")
	Track.Position = UDim2.new(0.2, 0, 0.32, 58)
	Track.Size = UDim2.new(0.6, 0, 0, 8)
	Track.BackgroundColor3 = Theme.Panel
	Track.BorderSizePixel = 0
	Track.ZIndex = 51
	Track.Parent = Veil

	local Fill = Instance.new("Frame")
	Fill.Size = UDim2.fromScale(0, 1)
	Fill.BackgroundColor3 = Theme.Accent
	Fill.BorderSizePixel = 0
	Fill.ZIndex = 52
	Fill.Parent = Track
	self.ProgressFill = Fill

	local Stop = Theme.Button(Content.Animations.Stop, 130, 30, false)
	Stop.Position = UDim2.new(0.5, -65, 0.32, 82)
	Stop.ZIndex = 51
	Stop.Parent = Veil
	Stop.Activated:Connect(function()
		self.Cancelled = true
		self.ProgressDetail.Text = Content.Animations.Stopping
	end)
end

function AnimationPanel:BuildConfirm(Parent)
	local Veil = Instance.new("TextButton")
	Veil.Name = "Confirm"
	Veil.Size = UDim2.fromScale(1, 1)
	Veil.BackgroundColor3 = Theme.Background
	Veil.BackgroundTransparency = 0.02
	Veil.BorderSizePixel = 0
	Veil.Text = ""
	Veil.AutoButtonColor = false
	Veil.Modal = true
	Veil.Visible = false
	Veil.ZIndex = 40
	Veil.Parent = Parent
	self.Veil = Veil

	local Title = Theme.Label("", 15, Theme.Warning, Theme.TitleFont)
	Title.Position = UDim2.new(0, 20, 0, 14)
	Title.Size = UDim2.new(1, -40, 0, 44)
	Title.ZIndex = 41
	Title.TextWrapped = true
	Title.TextYAlignment = Enum.TextYAlignment.Top
	Title.Parent = Veil
	self.ConfirmTitle = Title

	local Header = Instance.new("Frame")
	Header.Position = UDim2.new(0, 20, 0, 58)
	Header.Size = UDim2.new(1, -46, 0, 16)
	Header.BackgroundTransparency = 1
	Header.ZIndex = 41
	Header.Parent = Veil

	for _, Column in ConfirmColumns do
		local Label = Theme.Label(Column.Title, 10, Theme.MutedText, Theme.TitleFont)
		Label.Position = UDim2.new(Column.Left, 10, 0, 0)
		Label.Size = UDim2.new(Column.Right - Column.Left, -14, 1, 0)
		Label.ZIndex = 41
		Label.Parent = Header
	end

	local List = Instance.new("ScrollingFrame")
	List.Position = UDim2.new(0, 20, 0, 76)
	List.Size = UDim2.new(1, -40, 1, -130)
	List.BackgroundColor3 = Theme.Panel
	List.BorderSizePixel = 0
	List.ScrollBarThickness = 6
	List.ScrollBarImageColor3 = Theme.MutedText
	List.CanvasSize = UDim2.new()
	List.AutomaticCanvasSize = Enum.AutomaticSize.Y
	List.ZIndex = 41
	List.Parent = Veil
	Theme.Stroke(List)
	self.ConfirmList = List

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Parent = List

	local Apply = Theme.Button(Content.Animations.Apply, 220, 32, false)
	Apply.Position = UDim2.new(0, 20, 1, -44)
	Apply.BackgroundColor3 = Theme.Danger
	Apply:SetAttribute("BaseColor", Theme.Danger)
	Apply:SetAttribute("OverColor", Theme.Danger)
	Apply:SetAttribute("InkColor", Theme.Text)
	Apply.TextColor3 = Theme.Text
	Apply.Font = Theme.TitleFont
	Apply.ZIndex = 41
	Apply.Parent = Veil
	self.ConfirmApply = Apply

	local Cancel = Theme.Button(Content.Animations.Cancel, 110, 32, false)
	Cancel.Position = UDim2.new(0, 252, 1, -44)
	Cancel.ZIndex = 41
	Cancel.Parent = Veil
	Cancel.Activated:Connect(function()
		if self.ApplyConnection then self.ApplyConnection:Disconnect() end
		self.ApplyConnection = nil
		Veil.Visible = false
	end)
end

function AnimationPanel:Remember()
	if self.Plugin then
		self.Plugin:SetSetting(ManualKey, self.Manual)
	end
end

function AnimationPanel:Load()
	local Module = ConfigScanner.Module()
	self.Problem = nil
	if not Module then
		self.Rows, self.Matches = {}, {}
		self.Problem = Content.Animations.NoConfig
		return false, self.Problem
	end
	local Report = ConfigScanner.SelfTest(Module.Source)
	self.Rows = Report.Rows
	if not Report.Trustworthy then
		self.Matches = {}
		self.Problem = Content.Animations.Untrusted(Report.Count, tostring(Report.Identical))
		return false, self.Problem
	end
	self.Clips = AnimationMatcher.Clips()
	self.Matches = AnimationMatcher.Match(self.Rows, self.Clips, self.Manual)
	return true, nil
end

function AnimationPanel:Cycle(Row)
	local Entry = self.Matches[Row.Path]
	if not Entry or #Entry.Choices == 0 then
		return
	end
	local Current = self.Manual[Row.Path]
	local Index = 0
	for Position, Clip in Entry.Choices do
		if Clip.Name == Current then
			Index = Position
		end
	end
	local Next = Entry.Choices[Index + 1]
	self.Manual[Row.Path] = Next and Next.Name or nil
	self:Remember()
	self:Load()
	self:Render()
end

function AnimationPanel:Jobs()
	local Jobs = {}
	for _, Row in self.Rows do
		if self.Selected[Row.Path] then
			local Entry = self.Matches[Row.Path]
			if Entry and Entry.Clip then
				table.insert(Jobs, {
					Path = Row.Path,
					Row = Row,
					Clip = Entry.Clip,
					Clips = Entry.Clips or { Entry.Clip },
				})
			end
		end
	end
	return Jobs
end

function AnimationPanel:AskThenUpload()
	local Jobs = self:Jobs()
	if #Jobs == 0 then
		self.Summary.Text = Content.Animations.NothingToDo
		self.Summary.TextColor3 = Theme.Warning
		return
	end

	for _, Child in self.ConfirmList:GetChildren() do
		if Child:IsA("Frame") then
			Child:Destroy()
		end
	end

	local Changing = {}
	for _, Job in Jobs do
		if not IsEmpty(Job.Row.Raw) then
			table.insert(Changing, Job)
		end
	end

	local Distinct = AnimationUploader.DistinctClips(Jobs)
	self.ConfirmTitle.Text = Content.Animations.ConfirmTitle(#Changing, #Jobs, Distinct, select(2, self.Location.Get()).Label, AnimationUploader.Estimate(Distinct, AnimationUploader.LaneCount(Jobs)))

	for Index, Job in Changing do
		local Row = Instance.new("Frame")
		Row.LayoutOrder = Index
		Row.Size = UDim2.new(1, 0, 0, 26)
		Row.BackgroundColor3 = Theme.Raised
		Row.BackgroundTransparency = Index % 2 == 0 and 1 or 0.5
		Row.BorderSizePixel = 0
		Row.ZIndex = 41
		Row.Parent = self.ConfirmList

		local Values = {
			{ tostring(Job.Row.Line), Theme.MutedText, Theme.BodyFont },
			{ Job.Row.Path, Theme.Text, Theme.MediumFont },
			{ Pretty(Job.Row.Raw), Theme.Danger, Theme.BodyFont },
			{ Job.Clip.Name, Theme.Success, Theme.MediumFont },
		}
		for Position, Column in ConfirmColumns do
			local Value = Values[Position]
			local Label = Theme.Label(Value[1], 12, Value[2], Value[3])
			Label.Position = UDim2.new(Column.Left, 10, 0, 0)
			Label.Size = UDim2.new(Column.Right - Column.Left, -14, 1, 0)
			Label.TextTruncate = Enum.TextTruncate.AtEnd
			Label.ZIndex = 42
			Label.Parent = Row
		end
	end

	if self.ApplyConnection then self.ApplyConnection:Disconnect() end
	self.ApplyConnection = self.ConfirmApply.Activated:Once(function()
		self.ApplyConnection = nil
		self.Veil.Visible = false
		self:RunUpload(Jobs)
	end)
	self.Veil.Visible = true
end

function AnimationPanel:RunUpload(Jobs)
	if self.Busy then return end
	self.Busy = true
	self.Cancelled = false
	self.Upload.Text = Content.Animations.Working
	Theme.SetLocked(self.Upload, true)
	self.Location.SetLocked(true)

	self.ProgressFill.Size = UDim2.fromScale(0, 1)
	self.ProgressDetail.Text = Content.Animations.Progress(0, #Jobs, "")
	self.ProgressVeil.Visible = true

	local Expected = {}
	for _, Job in Jobs do
		Expected[Job.Path] = Job.Row.Raw
	end

	task.spawn(function()
		local Uploaded, Assignments, Failures = pcall(AnimationUploader.Upload,
			Jobs,
			select(2, self.Location.Get()),
			function(Index, Total, ClipName)
				self.ProgressFill.Size = UDim2.fromScale(Index / math.max(Total, 1), 1)
				self.ProgressDetail.Text = Content.Animations.Progress(Index, Total, tostring(ClipName))
			end,
			function()
				return self.Cancelled
			end
		)
		if not Uploaded then
			Assignments, Failures = {}, { tostring(Assignments) }
		end

		local Count = 0
		for _ in Assignments do
			Count += 1
		end

		local Wrote, Reason, Skipped, Applied = false, Content.Animations.NothingWritten, {}, 0
		if Count > 0 then
			self.ProgressDetail.Text = Content.Animations.Writing
			local Written, Done, Why, Left, Put = pcall(AnimationUploader.WriteBack, Assignments, Expected)
			if Written then
				Wrote, Reason, Skipped, Applied = Done, Why, Left or {}, Put
			else
				Wrote, Reason = false, tostring(Done)
			end
		end

		self.ProgressVeil.Visible = false
		self.Busy = false
		self.Upload.Text = Content.Animations.Upload
		Theme.SetLocked(self.Upload, false)
		self.Location.SetLocked(false)

		local Outcome = Content.Animations.Written
		if Wrote and #Skipped > 0 then
			Outcome = Content.Animations.WrittenSome(Applied or 0, #Skipped)
		elseif not Wrote then
			Outcome = Reason or "not written"
		end

		local Why = #Failures > 0 and ("  |  " .. tostring(Failures[1])) or ""
		local Told = Content.Animations.Done(Count, #Jobs, #Failures, Outcome) .. Why
		if #Skipped > 0 then

			local Named = {}
			for Index = 1, math.min(#Skipped, 4) do
				table.insert(Named, Skipped[Index])
			end
			if #Skipped > #Named then
				table.insert(Named, "and " .. (#Skipped - #Named) .. " more")
			end
			Told = Told .. Content.Animations.SkippedNote(table.concat(Named, "; "))
		end
		local Clean = #Failures == 0 and Wrote and #Skipped == 0 and Count == #Jobs
		table.clear(self.Selected)
		self:Load()
		self:Render()
		self.Summary.Text = Told
		self.Summary.TextColor3 = Clean and Theme.Success or Theme.Warning
		self.Notice.Show(
			Clean and Content.Animations.DoneTitle or Content.Animations.PartTitle,
			Told)
	end)
end

function AnimationPanel:Tree()
	local Modules, Order = {}, {}
	for _, Row in self.Rows do
		local Bucket = Modules[Row.Module]
		if not Bucket then
			Bucket = { Name = Row.Module, Branches = {}, Order = {} }
			Modules[Row.Module] = Bucket
			table.insert(Order, Bucket)
		end
		local BranchName = Row.Branch or "-"
		local Branch = Bucket.Branches[BranchName]
		if not Branch then
			Branch = { Name = BranchName, Rows = {} }
			Bucket.Branches[BranchName] = Branch
			table.insert(Bucket.Order, Branch)
		end
		table.insert(Branch.Rows, Row)
	end
	return Order
end

function AnimationPanel:SetGroup(Rows, State)
	for _, Row in Rows do
		self.Selected[Row.Path] = State or nil
	end
end

function AnimationPanel:AddRow(Order)
	local Row = Instance.new("Frame")
	Row.LayoutOrder = Order
	Row.Size = UDim2.new(1, 0, 0, RowHeight)
	Row.BackgroundTransparency = 1
	Row.Parent = self.Scroll
	return Row
end

local function ClipTextFor(Entry)
	if Entry and Entry.Clips and #Entry.Clips > 1 then
		local Names = {}
		for _, One in Entry.Clips do
			table.insert(Names, One.Name)
		end
		return table.concat(Names, ", ")
	end
	if Entry and Entry.Clip then
		return Entry.Clip.Name
	end
	return Content.Animations.NoClip
end

function AnimationPanel:GroupRow(Order, Indent, Text, Font, Colour, Rows, Key, Raised)
	local Row = self:AddRow(Order)
	if Raised then
		Row.BackgroundColor3 = Theme.Raised
		Row.BackgroundTransparency = 0
	end

	local Ticked = 0
	for _, Leaf in Rows do
		if self.Selected[Leaf.Path] then
			Ticked += 1
		end
	end

	local Box, Fill = Tick(Row, Indent)
	Fill.Visible = Ticked > 0
	Fill.BackgroundColor3 = Ticked == #Rows and Theme.Accent or Theme.MutedText
	Box.Activated:Connect(function()
		if self.Busy then return end
		self:SetGroup(Rows, Ticked < #Rows)
		self:Render()
	end)

	local Toggle = Instance.new("TextButton")
	Toggle.Position = UDim2.new(0, Indent + 20, 0, 0)
	Toggle.Size = UDim2.new(1, -(Indent + 20), 1, 0)
	Toggle.BackgroundTransparency = 1
	Toggle.Text = (self.Expanded[Key] and "v" or ">") .. "  " .. Text .. "  (" .. #Rows .. ")"
	Toggle.TextSize = Theme.Size(12)
	Toggle.Font = Font
	Toggle.TextColor3 = Colour
	Toggle.TextXAlignment = Enum.TextXAlignment.Left
	Toggle.AutoButtonColor = false
	Toggle.Parent = Row
	Toggle.Activated:Connect(function()
		if self.Busy then return end
		self.Expanded[Key] = not self.Expanded[Key] or nil
		self:Render()
	end)
	return Row
end

function AnimationPanel:LeafRow(Order, Leaf)
	local Row = self:AddRow(Order)

	local Box, Fill = Tick(Row, 40)
	Fill.Visible = self.Selected[Leaf.Path] == true
	Box.Activated:Connect(function()
		if self.Busy then return end
		self.Selected[Leaf.Path] = not self.Selected[Leaf.Path] or nil
		self:Render()
	end)

	local Empty = IsEmpty(Leaf.Raw)
	local Line = Theme.Label(tostring(Leaf.Line), 11, Theme.MutedText)
	Line.Position = UDim2.new(0, 60, 0, 0)
	Line.Size = UDim2.fromOffset(36, RowHeight)
	Line.Parent = Row

	local Name = Theme.Label(Leaf.Key, 12, Empty and Theme.Warning or Theme.Text)
	Name.Position = UDim2.new(0, 98, 0, 0)
	Name.Size = UDim2.new(0.36, -98, 1, 0)
	Name.Parent = Row

	local Entry = self.Matches[Leaf.Path]

	local Clip = Instance.new("TextButton")
	Clip.BackgroundTransparency = 1
	Clip.Text = ClipTextFor(Entry)
	Clip.TextSize = Theme.Size(11)
	Clip.Font = Theme.BodyFont
	Clip.TextXAlignment = Enum.TextXAlignment.Left
	Clip.TextTruncate = Enum.TextTruncate.AtEnd
	Clip.AutoButtonColor = false
	Clip.TextColor3 = Entry and Entry.Clip and Theme.Success or Theme.Danger
	Clip.Position = UDim2.new(0.36, 0, 0, 0)
	Clip.Size = UDim2.new(0.3, -6, 1, 0)
	Clip.Parent = Row
	Clip.Activated:Connect(function()
		if not self.Busy then
			self:Cycle(Leaf)
		end
	end)

	local Value = Theme.Label(Empty and Content.Animations.Unfilled or Pretty(Leaf.Raw), 11, Empty and Theme.Warning or Theme.MutedText)
	Value.Position = UDim2.new(0.66, 0, 0, 0)
	Value.Size = UDim2.new(0.34, -8, 1, 0)
	Value.Parent = Row
	return Row
end

function AnimationPanel:Summarise()
	local Chosen = 0
	for _ in self.Selected do
		Chosen += 1
	end

	local Filled, Empty, Ready = 0, 0, 0
	for _, Row in self.Rows do
		if IsEmpty(Row.Raw) then
			Empty += 1
		else
			Filled += 1
		end
		local Entry = self.Matches[Row.Path]
		if Entry and Entry.Clip then
			Ready += 1
		end
	end

	if not self.Busy then
		Theme.SetLocked(self.Upload, self.Location.Get() == nil)
	end
	if self.Problem then
		self.Summary.Text = self.Problem
		self.Summary.TextColor3 = Theme.Warning
		return
	end
	self.Summary.Text = Content.Animations.Summary(#self.Rows, Filled, Empty, Ready, Chosen)
end

function AnimationPanel:Render()
	for _, Child in self.Scroll:GetChildren() do
		if Child:IsA("Frame") then
			Child:Destroy()
		end
	end

	local Order = 0
	for _, Block in self:Tree() do
		local Every = {}
		for _, Branch in Block.Order do
			for _, Leaf in Branch.Rows do
				table.insert(Every, Leaf)
			end
		end

		Order += 1
		self:GroupRow(Order, 6, Block.Name, Theme.TitleFont, Theme.Text, Every, Block.Name, true)
		if not self.Expanded[Block.Name] then
			continue
		end

		for _, Branch in Block.Order do
			local Key = Block.Name .. "." .. Branch.Name
			Order += 1
			self:GroupRow(Order, 22, Branch.Name, Theme.MediumFont, Theme.MutedText, Branch.Rows, Key, false)
			if not self.Expanded[Key] then
				continue
			end

			for _, Leaf in Branch.Rows do
				Order += 1
				self:LeafRow(Order, Leaf)
			end
		end
	end

	self:Summarise()
end

return AnimationPanel
