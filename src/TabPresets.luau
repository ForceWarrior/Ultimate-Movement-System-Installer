--// [Modules]
local Theme = require(script.Parent.Theme)
local Content = require(script.Parent.Content)
local Presets = require(script.Parent.Presets)

--// [Variables]
local TabPresets = {}
local CardWidth = 306
local CardHeight = 124

--// [Do not go past this point]

local function Field(Parent, Placeholder, Width, Order)
	local Box = Instance.new("TextBox")
	Box.LayoutOrder = Order
	Box.Size = UDim2.fromOffset(Width, 28)
	Box.BackgroundColor3 = Theme.Raised
	Box.BorderSizePixel = 0
	Box.Font = Theme.BodyFont
	Box.TextSize = Theme.Size(13)
	Box.TextColor3 = Theme.Text
	Box.PlaceholderText = Placeholder
	Box.PlaceholderColor3 = Theme.MutedText
	Box.Text = ""
	Box.ClearTextOnFocus = false
	Box.TextXAlignment = Enum.TextXAlignment.Left
	Box.Parent = Parent
	Theme.Stroke(Box)
	Theme.Padding(Box, 6)
	return Box
end

local function Chip(Text, Width, Order, Accent)
	local Button = Theme.Button(Text, Width, 28, Accent)
	Button.LayoutOrder = Order
	return Button
end

local function CodeBox(Parent, Layer, Editable)
	local Scroll = Instance.new("ScrollingFrame")
	Scroll.Size = UDim2.fromScale(1, 1)
	Scroll.BackgroundColor3 = Theme.Background
	Scroll.BorderSizePixel = 0
	Scroll.ScrollBarThickness = 5
	Scroll.ScrollBarImageColor3 = Theme.MutedText
	Scroll.CanvasSize = UDim2.new()
	Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Scroll.ZIndex = Layer
	Scroll.Parent = Parent
	Theme.Stroke(Scroll)
	Theme.Padding(Scroll, 8)

	local Box = Instance.new("TextBox")
	Box.Size = UDim2.new(1, -21, 1, -16)
	Box.AutomaticSize = Enum.AutomaticSize.Y
	Box.BackgroundTransparency = 1
	Box.BorderSizePixel = 0
	Box.MultiLine = true
	Box.ClearTextOnFocus = false
	Box.TextEditable = Editable ~= false
	Box.TextWrapped = true
	Box.Font = Enum.Font.Code
	Box.TextSize = Theme.Size(12)
	Box.TextColor3 = Theme.Text
	Box.PlaceholderColor3 = Theme.MutedText
	Box.Text = ""
	Box.TextXAlignment = Enum.TextXAlignment.Left
	Box.TextYAlignment = Enum.TextYAlignment.Top
	Box.ZIndex = Layer + 1
	Box.Parent = Scroll

	Scroll.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 and Editable ~= false then
			Box:CaptureFocus()
		end
	end)

	return Box
end

function TabPresets.Build(Page, PluginHandle)
	Presets.Attach(PluginHandle)

	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.new(1, -32, 0, 30)
	Bar.Position = UDim2.fromOffset(16, 14)
	Bar.BackgroundTransparency = 1
	Bar.Parent = Page

	local BarLayout = Instance.new("UIListLayout")
	BarLayout.FillDirection = Enum.FillDirection.Horizontal
	BarLayout.Padding = UDim.new(0, 6)
	BarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	BarLayout.Parent = Bar

	local NameBox = Field(Bar, Content.Presets.NamePlaceholder, 190, 1)
	NameBox.Size = UDim2.new(0.24, 0, 0, 28)
	local NoteBox = Field(Bar, Content.Presets.NotePlaceholder, 330, 2)
	NoteBox.Size = UDim2.new(0.3, 0, 0, 28)

	local Save = Chip(Content.Presets.Save, 120, 3, true)
	Save.Parent = Bar

	local Paste = Chip(Content.Presets.Paste, 130, 4, false)
	Paste.Parent = Bar

	local Status = Theme.Label("", 12, Theme.MutedText)
	Status.Position = UDim2.fromOffset(16, 48)
	Status.Size = UDim2.new(1, -32, 0, 16)
	Status.TextTruncate = Enum.TextTruncate.AtEnd
	Status.Parent = Page

	local Shell, Pane = Theme.Group(Page, Content.Presets.GridTitle)
	Shell.Position = UDim2.fromOffset(16, 78)
	Shell.Size = UDim2.new(1, -32, 1, -94)

	local Grid = Instance.new("ScrollingFrame")
	Grid.Size = UDim2.fromScale(1, 1)
	Grid.BackgroundTransparency = 1
	Grid.BorderSizePixel = 0
	Grid.ScrollBarThickness = 4
	Grid.ScrollBarImageColor3 = Theme.MutedText
	Grid.CanvasSize = UDim2.new()
	Grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Grid.Parent = Pane
	Theme.ScrollInset(Grid, 5)

	local GridLayout = Instance.new("UIGridLayout")
	GridLayout.CellSize = UDim2.fromOffset(CardWidth, CardHeight)
	GridLayout.CellPadding = UDim2.fromOffset(12, 12)
	GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	GridLayout.Parent = Grid

	local function Say(Text, Colour)
		Status.Text = Text
		Status.TextColor3 = Colour or Theme.MutedText
	end

	local Share = Theme.Sheet(Page, 30, Content.Presets.ShareTitle)
	local ShareFor = nil
	local WithAnimations = false

	local Animations = Theme.Checkbox(Content.Presets.IncludeAnimations, 220)
	Animations.Position = UDim2.fromOffset(0, 0)
	Animations.ZIndex = Share.Layer + 3
	Animations.Parent = Share.Body

	local Facts = Theme.Label("", 11, Theme.MutedText)
	Facts.Position = UDim2.fromOffset(230, 0)
	Facts.Size = UDim2.new(1, -230, 0, 22)
	Facts.ZIndex = Share.Layer + 3
	Facts.Parent = Share.Body

	local Holder = Instance.new("Frame")
	Holder.Position = UDim2.fromOffset(0, 30)
	Holder.Size = UDim2.new(1, 0, 1, -66)
	Holder.BackgroundTransparency = 1
	Holder.ZIndex = Share.Layer + 3
	Holder.Parent = Share.Body

	local CodeOut = CodeBox(Holder, Share.Layer + 4, true)

	local Hint = Theme.Label(Content.Presets.CopyHint, 11, Theme.MutedText)
	Hint.Position = UDim2.new(0, 120, 1, -32)
	Hint.Size = UDim2.new(1, -120, 0, 32)
	Hint.TextWrapped = true
	Hint.ZIndex = Share.Layer + 3
	Hint.Parent = Share.Body

	local SelectAll = Theme.Button(Content.Presets.SelectAll, 110, 26, true)
	SelectAll.Position = UDim2.new(0, 0, 1, -28)
	SelectAll.ZIndex = Share.Layer + 3
	SelectAll.Parent = Share.Body

	local function HighlightCode()
		if CodeOut.Text == "" then
			return
		end
		CodeOut:CaptureFocus()
		task.defer(function()
			CodeOut.CursorPosition = #CodeOut.Text + 1
			CodeOut.SelectionStart = 1
		end)
	end

	local function DrawCode()
		if not ShareFor then
			return
		end
		local Code, Problem, Changed = Presets.Code(ShareFor, WithAnimations)
		Theme.SetChecked(Animations, WithAnimations)
		if not Code then
			CodeOut.Text = ""
			Facts.Text = tostring(Problem)
			Facts.TextColor3 = Theme.Warning
			return
		end
		CodeOut.Text = Code
		Facts.Text = Content.Presets.CodeFacts(Changed, #Code)
		Facts.TextColor3 = #Code > 1900 and Theme.Warning or Theme.MutedText
	end

	Animations.Activated:Connect(function()
		WithAnimations = not WithAnimations
		DrawCode()
	end)
	SelectAll.Activated:Connect(HighlightCode)

	local Paster = Theme.Sheet(Page, 34, Content.Presets.PasteTitle)

	local PasteHint = Theme.Label(Content.Presets.PasteHint, 12, Theme.MutedText)
	PasteHint.Position = UDim2.fromOffset(0, 0)
	PasteHint.Size = UDim2.new(1, 0, 0, 20)
	PasteHint.TextWrapped = true
	PasteHint.ZIndex = Paster.Layer + 3
	PasteHint.Parent = Paster.Body

	local PasteHolder = Instance.new("Frame")
	PasteHolder.Position = UDim2.fromOffset(0, 26)
	PasteHolder.Size = UDim2.new(1, 0, 1, -62)
	PasteHolder.BackgroundTransparency = 1
	PasteHolder.ZIndex = Paster.Layer + 3
	PasteHolder.Parent = Paster.Body

	local CodeIn = CodeBox(PasteHolder, Paster.Layer + 4, true)
	CodeIn.PlaceholderText = Content.Presets.PastePlaceholder

	local ReadIt = Theme.Button(Content.Presets.ReadIt, 120, 28, true)
	ReadIt.Position = UDim2.new(0, 0, 1, -30)
	ReadIt.ZIndex = Paster.Layer + 3
	ReadIt.Parent = Paster.Body

	local PasteSaid = Theme.Label("", 12, Theme.MutedText)
	PasteSaid.Position = UDim2.new(0, 130, 1, -30)
	PasteSaid.Size = UDim2.new(1, -130, 0, 28)
	PasteSaid.TextWrapped = true
	PasteSaid.ZIndex = Paster.Layer + 3
	PasteSaid.Parent = Paster.Body

	local Refresh

	ReadIt.Activated:Connect(function()
		local Ok, Name, Problem = Presets.Adopt(CodeIn.Text)
		if Ok then
			PasteSaid.Text = Content.Presets.Imported(Name)
			PasteSaid.TextColor3 = Theme.Success
			CodeIn.Text = ""
			Say(Content.Presets.Imported(Name), Theme.Success)
			Refresh()
		else
			PasteSaid.Text = tostring(Problem)
			PasteSaid.TextColor3 = Theme.Danger
		end
	end)

	Paste.Activated:Connect(function()
		CodeIn.Text = ""
		PasteSaid.Text = ""
		Paster.Show()
	end)

	local Sure = Theme.Confirm(Page, 78, Content.Presets.DeleteYes, Content.Presets.DeleteNo)
	local Change = Theme.Confirm(Page, 80, Content.Presets.ReplaceYes, Content.Presets.ConfirmNo)
	local Add = Theme.Confirm(Page, 82, Content.Presets.InsertYes, Content.Presets.ConfirmNo)

	local function Describe(Entry, Summary, Findings)
		local Lines = { Summary }
		local Verdict, Made, Live = Presets.Compatibility(Entry)
		if Verdict == "same" then
			table.insert(Lines, Content.Presets.VersionSame(tostring(Made)))
		elseif Verdict == "different" then
			table.insert(Lines, Content.Presets.VersionDifferent(tostring(Made), tostring(Live)))
		else
			table.insert(Lines, Content.Presets.VersionUnknown)
		end

		local Warning = nil
		if #Findings > 0 then
			local Named = {}
			for Index = 1, math.min(#Findings, 6) do
				table.insert(Named, Findings[Index])
			end
			local Listed = table.concat(Named, ", ")
			if #Findings > 6 then
				Listed ..= Content.Presets.CodeWarningMore(#Findings - 6)
			end
			Warning = Content.Presets.CodeWarning(Listed)
		end
		return table.concat(Lines, "\n"), Warning
	end

	local function Card(Entry, Order)
		local Frame = Instance.new("Frame")
		Frame.LayoutOrder = Order
		Frame.BackgroundColor3 = Theme.Panel
		Frame.BorderSizePixel = 0
		Frame.Parent = Grid
		Theme.Stroke(Frame, Theme.CardEdge)

		local Title = Theme.Label(Entry.Name, 14, Theme.Accent, Theme.TitleFont)
		Title.Position = UDim2.fromOffset(12, 9)
		Title.Size = UDim2.new(1, -42, 0, 18)
		Title.TextTruncate = Enum.TextTruncate.AtEnd
		Title.Parent = Frame

		local Bin = Theme.TrashButton(Frame, 16)
		Bin.AnchorPoint = Vector2.new(1, 0)
		Bin.Position = UDim2.new(1, -10, 0, 10)
		Bin.Activated:Connect(function()
			Sure.Show(
				Content.Presets.DeleteTitle(Entry.Name),
				Content.Presets.DeleteBody(Entry.Name),
				function()
					local Ok, Problem = Presets.Delete(Entry.Id)
					Say(Ok and Content.Presets.Deleted(Entry.Name) or tostring(Problem),
						Ok and Theme.MutedText or Theme.Danger)
					Refresh()
				end)
		end)

		local Note = Theme.Label(Entry.Description ~= "" and Entry.Description or Content.Presets.NoNote,
			12, Theme.MutedText)
		Note.Position = UDim2.fromOffset(12, 29)
		Note.Size = UDim2.new(1, -24, 0, 32)
		Note.TextWrapped = true
		Note.TextYAlignment = Enum.TextYAlignment.Top
		Note.Parent = Frame

		local Scope = Entry.Partial and Content.Presets.PartialFacts or Content.Presets.FullFacts
		local Made = Entry.Version
			and Content.Presets.MadeOn(tostring(Entry.Version))
			or Content.Presets.MadeOnUnknown
		local Reach = Theme.Label(Scope(Entry.Count or 0) .. "  |  " .. Made,
			11, Theme.MutedText)
		Reach.Position = UDim2.fromOffset(12, 64)
		Reach.Size = UDim2.new(1, -24, 0, 14)
		Reach.Parent = Frame

		local Row = Instance.new("Frame")
		Row.Position = UDim2.fromOffset(12, 84)
		Row.Size = UDim2.new(1, -24, 0, 24)
		Row.BackgroundTransparency = 1
		Row.Parent = Frame

		local RowLayout = Instance.new("UIListLayout")
		RowLayout.FillDirection = Enum.FillDirection.Horizontal
		RowLayout.Padding = UDim.new(0, 5)
		RowLayout.SortOrder = Enum.SortOrder.LayoutOrder
		RowLayout.Parent = Row

		local function Small(Text, Width, Order, Accent)
			local Button = Theme.Button(Text, Width, 24, Accent)
			Button.TextSize = Theme.Size(11)
			Button.LayoutOrder = Order
			Button.Parent = Row
			return Button
		end

		local Replace = Small(Content.Presets.Replace, 92, 1, true)
		Replace.Activated:Connect(function()
			local Changed, Unknown, Animations, Findings, Refused = Presets.Preview(Entry.Id)

			local Summary = Refused
				and Content.Presets.RefusedFacts(tostring(Refused))
				or Content.Presets.ReplaceFacts(Changed, Animations, Unknown)
			local Body, Warning = Describe(Entry, Summary, Findings)
			Change.Show(Content.Presets.ReplaceTitle(Entry.Name), Body, function()
				local Ok, Problem = Presets.Apply(Entry.Id)
				Say(tostring(Problem), Ok and Theme.Success or Theme.Danger)
				Refresh()
			end, Warning)
		end)

		local Insert = Small(Content.Presets.Insert, 76, 2)
		Insert.Activated:Connect(function()

			local Where = Presets.InsertTarget()
			local Changed, Unknown, Animations, Findings, Refused = Presets.PreviewInsert(Entry.Id)
			local Summary = Refused
				and Content.Presets.RefusedFacts(tostring(Refused))
				or Content.Presets.InsertFacts(Changed, Animations, Unknown, Where:GetFullName())
			local Body, Warning = Describe(Entry, Summary, Findings)
			Add.Show(Content.Presets.InsertTitle(Entry.Name), Body, function()
				local Ok, Problem = Presets.Insert(Entry.Id, Where)
				Say(tostring(Problem), Ok and Theme.Success or Theme.Danger)
			end, Warning)
		end)

		local Send = Small(Content.Presets.Share, 60, 3)
		Send.Activated:Connect(function()
			ShareFor = Entry.Id
			WithAnimations = false
			Share.Heading.Text = Content.Presets.ShareOne(Entry.Name)
			DrawCode()
			Share.Show()
			HighlightCode()
		end)
	end

	Refresh = function()
		for _, Child in Grid:GetChildren() do
			if Child:IsA("Frame") then
				Child:Destroy()
			end
		end
		local List = Presets.List()
		for Index, Entry in List do
			Card(Entry, Index)
		end
		if #List == 0 and Status.Text == "" then
			Say(Content.Presets.Empty)
		end
	end

	Save.Activated:Connect(function()
		local Ok, Problem = Presets.Save(NameBox.Text, NoteBox.Text)
		if Ok then
			Say(Content.Presets.Saved(NameBox.Text, Problem), Theme.Success)
			NameBox.Text = ""
			NoteBox.Text = ""
		else
			Say(tostring(Problem), Theme.Danger)
		end
		Refresh()
	end)

	Refresh()
	return Refresh
end

return TabPresets
