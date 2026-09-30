--// [Modules]
local Theme = require(script.Parent.Theme)

--// [Variables]
local DocPage = {}
local CardWidth = 240
local CardHeight = 132
local CardInset = 12
local HeadHeight = 30

--// [Do not go past this point]

function DocPage.New(Page, Words)
	local Doc = {}

	local Search = Instance.new("TextBox")
	Search.Position = UDim2.fromOffset(16, 14)
	Search.Size = UDim2.fromOffset(260, 28)
	Search.BackgroundColor3 = Theme.Raised
	Search.BorderSizePixel = 0
	Search.Font = Theme.BodyFont
	Search.TextSize = Theme.Size(15)
	Search.TextColor3 = Theme.Text
	Search.PlaceholderText = Words.Search
	Search.PlaceholderColor3 = Theme.MutedText
	Search.Text = ""
	Search.ClearTextOnFocus = false
	Search.TextXAlignment = Enum.TextXAlignment.Left
	Search.Parent = Page
	Theme.Stroke(Search)
	Theme.Padding(Search, 6)
	Doc.Search = Search

	local Status = Theme.Label("", 13, Theme.MutedText)
	Status.Position = UDim2.fromOffset(288, 14)
	Status.Size = UDim2.new(1, -304, 0, 28)
	Status.Parent = Page
	Doc.Status = Status

	local Shell, Pane = Theme.Group(Page, Words.GridTitle)
	Shell.Position = UDim2.fromOffset(16, 58)
	Shell.Size = UDim2.new(1, -32, 1, -74)

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

	local Detail = Instance.new("TextButton")
	Detail.Size = UDim2.fromScale(1, 1)
	Detail.BackgroundColor3 = Theme.Background
	Detail.BorderSizePixel = 0
	Detail.Text = ""
	Detail.AutoButtonColor = false
	Detail.Visible = false
	Detail.ZIndex = 20
	Detail.Parent = Page

	local function ShowGrid(State)
		Detail.Visible = not State
		Shell.Visible = State
		Search.Visible = State
		Status.Visible = State
	end

	local Back = Theme.Button(Words.Back, 96, 28, false)
	Back.Position = UDim2.fromOffset(16, 14)
	Back.ZIndex = 21
	Back.Parent = Detail

	local Heading = Theme.Label("", 20, Theme.Accent, Theme.TitleFont)
	Heading.Position = UDim2.fromOffset(124, 14)
	Heading.Size = UDim2.new(1, -140, 0, 28)
	Heading.ZIndex = 21
	Heading.Parent = Detail

	local ActionWidth = 150
	local PageAction = Theme.Button("", ActionWidth, 28, true)
	PageAction.AnchorPoint = Vector2.new(1, 0)
	PageAction.Position = UDim2.new(1, -16, 0, 14)
	PageAction.Visible = false
	PageAction.ZIndex = 22
	PageAction.Parent = Detail
	local ShownEntry = nil
	PageAction.Activated:Connect(function()
		if ShownEntry and ShownEntry.Action then
			ShownEntry.Action.Run(ShownEntry)
		end
	end)

	local Body = Instance.new("ScrollingFrame")
	Body.Position = UDim2.fromOffset(16, 52)
	Body.Size = UDim2.new(1, -32, 1, -68)
	Body.BackgroundTransparency = 1
	Body.BorderSizePixel = 0
	Body.ScrollBarThickness = 5
	Body.ScrollBarImageColor3 = Theme.MutedText
	Body.CanvasSize = UDim2.new()
	Body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Body.ZIndex = 21
	Body.Parent = Detail

	local Column = Instance.new("Frame")
	Column.Name = "Column"
	Column.Size = UDim2.new(1, -12, 0, 0)
	Column.AutomaticSize = Enum.AutomaticSize.Y
	Column.BackgroundTransparency = 1
	Column.ZIndex = 21
	Column.Parent = Body

	local ColumnLayout = Instance.new("UIListLayout")
	ColumnLayout.Padding = UDim.new(0, 6)
	ColumnLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ColumnLayout.Parent = Column

	local function Sized(Label, Base)
		Label.TextSize = Theme.Size(Base)
		return Label
	end

	Sized(Heading, 18)

	local Order = 0
	local OpenName = nil
	local Unfolded = {}

	local function Paragraph(Text, Size, Colour, Font)
		Order += 1
		local Label = Sized(Theme.Label(Text, Size, Colour, Font), Size)
		Label.LayoutOrder = Order
		Label.Size = UDim2.new(1, 0, 0, 0)
		Label.AutomaticSize = Enum.AutomaticSize.Y
		Label.TextWrapped = true
		Label.TextYAlignment = Enum.TextYAlignment.Top
		Label.ZIndex = 21
		Label.Parent = Column
		return Label
	end

	local function Bullet(Text)
		Order += 1
		local Row = Instance.new("Frame")
		Row.LayoutOrder = Order
		Row.Size = UDim2.new(1, 0, 0, 0)
		Row.AutomaticSize = Enum.AutomaticSize.Y
		Row.BackgroundTransparency = 1
		Row.ZIndex = 21
		Row.Parent = Column

		local Dot = Instance.new("Frame")
		Dot.Position = UDim2.fromOffset(4, 8)
		Dot.Size = UDim2.fromOffset(4, 4)
		Dot.BackgroundColor3 = Theme.Accent
		Dot.BorderSizePixel = 0
		Dot.ZIndex = 22
		Dot.Parent = Row

		local Label = Sized(Theme.Label(Text, 15, Theme.BodyText), 15)
		Label.Position = UDim2.fromOffset(18, 0)
		Label.Size = UDim2.new(1, -18, 0, 0)
		Label.AutomaticSize = Enum.AutomaticSize.Y
		Label.TextWrapped = true
		Label.TextYAlignment = Enum.TextYAlignment.Top
		Label.ZIndex = 22
		Label.Parent = Row
		return Label
	end

	local function Spacer(Height)
		Order += 1
		local Gap = Instance.new("Frame")
		Gap.LayoutOrder = Order
		Gap.Size = UDim2.new(1, 0, 0, Height)
		Gap.BackgroundTransparency = 1
		Gap.ZIndex = 21
		Gap.Parent = Column
		return Gap
	end

	local function CodeBlock(Parent, Slot, Text)
		local Shelf = Instance.new("Frame")
		Shelf.LayoutOrder = Slot
		Shelf.Size = UDim2.new(1, 0, 0, 0)
		Shelf.AutomaticSize = Enum.AutomaticSize.Y
		Shelf.BackgroundColor3 = Theme.Background
		Shelf.BorderSizePixel = 0
		Shelf.ZIndex = 23
		Shelf.Parent = Parent
		Theme.Stroke(Shelf, Theme.Border)
		Theme.Padding(Shelf, 8)

		local Code = Instance.new("TextBox")
		Code.Size = UDim2.new(1, 0, 0, 0)
		Code.AutomaticSize = Enum.AutomaticSize.Y
		Code.BackgroundTransparency = 1
		Code.BorderSizePixel = 0
		Code.MultiLine = true
		Code.TextEditable = false
		Code.ClearTextOnFocus = false
		Code.TextWrapped = true
		Code.Font = Enum.Font.Code
		Sized(Code, 13)
		Code.TextColor3 = Theme.BodyText
		Code.Text = Text
		Code.TextXAlignment = Enum.TextXAlignment.Left
		Code.TextYAlignment = Enum.TextYAlignment.Top
		Code.ZIndex = 24
		Code.Parent = Shelf
		return Shelf
	end

	local function UnfoldRow(Row, EntryName)
		Order += 1

		local Frame = Instance.new("Frame")
		Frame.LayoutOrder = Order
		Frame.Size = UDim2.new(1, 0, 0, 0)
		Frame.AutomaticSize = Enum.AutomaticSize.Y
		Frame.BackgroundColor3 = Theme.Panel
		Frame.BackgroundTransparency = 1
		Frame.BorderSizePixel = 0
		Frame.ZIndex = 21
		Frame.Parent = Column

		local Stack = Instance.new("UIListLayout")
		Stack.SortOrder = Enum.SortOrder.LayoutOrder
		Stack.Parent = Frame

		local Head = Instance.new("TextButton")
		Head.LayoutOrder = 1
		Head.Size = UDim2.new(1, 0, 0, HeadHeight)
		Head.BackgroundTransparency = 1
		Head.Text = ""
		Head.AutoButtonColor = false
		Head.ZIndex = 22
		Head.Parent = Frame

		local Caret = Sized(Theme.Label(">", 11, Theme.MutedText, Theme.TitleFont), 11)
		Caret.Position = UDim2.fromOffset(8, 0)
		Caret.Size = UDim2.new(0, 12, 1, 0)
		Caret.ZIndex = 23
		Caret.Parent = Head

		local KeyShare = Row.Right and 0.44 or 0.52
		local ValueShare = Row.Right and 0.42 or 0.48

		local Key = Sized(Theme.Label(Row.Key, 15, Theme.Text, Theme.MediumFont), 15)
		Key.Position = UDim2.fromOffset(24, 0)
		Key.Size = UDim2.new(KeyShare, -24, 1, 0)
		Key.TextTruncate = Enum.TextTruncate.AtEnd
		Key.ZIndex = 23
		Key.Parent = Head

		local Value = Sized(Theme.Label(Row.Value or "", 15, Theme.Success), 15)
		Value.Position = UDim2.new(KeyShare, 0, 0, 0)
		Value.Size = UDim2.new(ValueShare, -12, 1, 0)
		Value.TextTruncate = Enum.TextTruncate.AtEnd
		Value.ZIndex = 23
		Value.Parent = Head

		if Row.Right then
			local Right = Sized(Theme.Label(Row.Right, 13, Theme.MutedText), 13)
			Right.Position = UDim2.new(KeyShare + ValueShare, 0, 0, 0)
			Right.Size = UDim2.new(1 - KeyShare - ValueShare, -10, 1, 0)
			Right.TextXAlignment = Enum.TextXAlignment.Right
			Right.ZIndex = 23
			Right.Parent = Head
		end

		local Fold = Instance.new("Frame")
		Fold.LayoutOrder = 2
		Fold.Size = UDim2.new(1, 0, 0, 0)
		Fold.AutomaticSize = Enum.AutomaticSize.Y
		Fold.BackgroundTransparency = 1
		Fold.Visible = false
		Fold.ZIndex = 22
		Fold.Parent = Frame

		local FoldLayout = Instance.new("UIListLayout")
		FoldLayout.Padding = UDim.new(0, 4)
		FoldLayout.SortOrder = Enum.SortOrder.LayoutOrder
		FoldLayout.Parent = Fold

		local FoldPad = Instance.new("UIPadding")
		FoldPad.PaddingLeft = UDim.new(0, 24)
		FoldPad.PaddingRight = UDim.new(0, 12)
		FoldPad.PaddingBottom = UDim.new(0, 8)
		FoldPad.Parent = Fold

		local Slot = 0
		for _, Line in Row.Lines or {} do
			Slot += 1
			local Label = Sized(Theme.Label(Line.Text, Line.Size, Line.Colour, Line.Font), Line.Size)
			Label.LayoutOrder = Slot
			Label.Size = UDim2.new(1, 0, 0, 0)
			Label.AutomaticSize = Enum.AutomaticSize.Y
			Label.TextWrapped = true
			Label.TextYAlignment = Enum.TextYAlignment.Top
			Label.ZIndex = 23
			Label.Parent = Fold
		end
		if Row.Code then
			Slot += 1
			CodeBlock(Fold, Slot, Row.Code)
		end

		local Slug = EntryName .. "." .. Row.Key
		local Open = Unfolded[Slug] == true

		local function Paint()
			Fold.Visible = Open
			Caret.Text = Open and "v" or ">"
			Caret.TextColor3 = Open and Theme.Accent or Theme.MutedText
			Frame.BackgroundTransparency = Open and 0 or 1
			Key.TextColor3 = Open and Theme.Accent or Theme.Text
		end

		Head.Activated:Connect(function()
			Open = not Open
			Unfolded[Slug] = Open or nil
			Paint()
		end)
		Head.MouseEnter:Connect(function()
			if not Open then
				Frame.BackgroundTransparency = 0.5
			end
		end)
		Head.MouseLeave:Connect(function()
			if not Open then
				Frame.BackgroundTransparency = 1
			end
		end)
		Paint()
	end

	function Doc.Show(Entry, KeepPlace)
		for _, Child in Column:GetChildren() do
			if Child:IsA("GuiObject") then
				Child:Destroy()
			end
		end
		Order = 0
		OpenName = Entry.Name
		Sized(Heading, 18)

		Heading.Text = Entry.Title
		ShownEntry = Entry
		PageAction.Visible = Entry.Action ~= nil
		PageAction.Text = Entry.Action and Entry.Action.Text or ""
		Heading.Size = UDim2.new(1, Entry.Action and -(140 + ActionWidth + 12) or -140, 0, 28)

		if Entry.Where then
			Paragraph(Entry.Where, 13, Theme.MutedText)
		end
		if Entry.Summary then
			Paragraph(Entry.Summary, 16, Theme.BodyText)
		end
		if Entry.Notes and #Entry.Notes > 0 then
			Spacer(2)
			Paragraph(Words.Notes, 15, Theme.Accent, Theme.TitleFont)
			for _, Note in Entry.Notes do
				Bullet(Note)
			end
		end

		local Any = false
		for _, Group in Entry.Groups or {} do
			if #Group.Rows > 0 then
				Any = true
			end
		end
		if Any then
			Spacer(2)
			Paragraph(Words.ExpandHint, 13, Theme.MutedText)
			for _, Group in Entry.Groups do
				if #Group.Rows > 0 then
					Spacer(4)
					if Group.Title then
						Paragraph(Group.Title:upper(), 12, Theme.Accent, Theme.TitleFont)
					end
					for _, Row in Group.Rows do
						UnfoldRow(Row, Entry.Name)
					end
				end
			end
		end

		if not KeepPlace then
			Body.CanvasPosition = Vector2.new(0, 0)
		end
		ShowGrid(false)
	end

	function Doc.Close()
		OpenName = nil
		ShowGrid(true)
	end

	function Doc.Open()
		return OpenName
	end

	Back.Activated:Connect(Doc.Close)

	local function Card(Entry, Position)
		local Frame = Instance.new("TextButton")
		Frame.LayoutOrder = Position
		Frame.BackgroundColor3 = Theme.Panel
		Frame.BorderSizePixel = 0
		Frame.Text = ""
		Frame.AutoButtonColor = false
		Frame.Parent = Grid
		Theme.Stroke(Frame, Theme.CardEdge)

		Frame.MouseEnter:Connect(function()
			Frame.BackgroundColor3 = Theme.Raised
		end)
		Frame.MouseLeave:Connect(function()
			Frame.BackgroundColor3 = Theme.Panel
		end)

		local function Place(Label, Top, Height)
			Label.Position = UDim2.fromScale(CardInset / CardWidth, Top / CardHeight)
			Label.Size = UDim2.fromScale(1 - CardInset * 2 / CardWidth, Height / CardHeight)
			Label.Parent = Frame
		end

		local Title = Sized(Theme.Label(Entry.Title, 15, Theme.Accent, Theme.TitleFont), 15)
		Title.TextTruncate = Enum.TextTruncate.AtEnd
		Place(Title, 10, 22)

		local Facts = Sized(Theme.Label(Entry.Facts or "", 13, Theme.MutedText), 13)
		Place(Facts, 34, 18)

		local Blurb = Sized(Theme.Label(Entry.Blurb or "", 14, Theme.BodyText), 14)
		Blurb.TextWrapped = true
		Blurb.TextYAlignment = Enum.TextYAlignment.Top
		Place(Blurb, 58, 64)

		if Entry.Action then
			local Button = Theme.Button(Entry.Action.Text, 84, 24, true)
			Button.TextSize = Theme.Size(12)
			Button.AnchorPoint = Vector2.new(1, 0)
			Button.Position = UDim2.new(1, -CardInset, 0, 30)
			Button.ZIndex = Frame.ZIndex + 1
			Button.Parent = Frame
			Button.Activated:Connect(function()
				Entry.Action.Run(Entry)
			end)
			Facts.Size = UDim2.fromScale(1 - (CardInset * 2 + 96) / CardWidth, 18 / CardHeight)
		end

		Frame.Activated:Connect(function()
			Doc.Show(Entry)
		end)
	end

	function Doc.Draw(Entries)
		for _, Child in Grid:GetChildren() do
			if Child:IsA("TextButton") then
				Child:Destroy()
			end
		end
		local Needle = Search.Text:lower()
		local Shown = 0
		for _, Entry in Entries do
			if Needle == "" or (Entry.Haystack or ""):lower():find(Needle, 1, true) then
				Shown += 1
				Card(Entry, Shown)
			end
		end
		return Shown
	end

	function Doc.Reopen(Entries)
		if not OpenName then
			return false
		end
		local Place = Body.CanvasPosition
		local Was = OpenName
		for _, Entry in Entries do
			if Entry.Name == Was then
				Doc.Show(Entry, true)
				Body.CanvasPosition = Place

				task.defer(function()
					if Detail.Visible and OpenName == Was then
						Body.CanvasPosition = Place
					end
				end)
				return true
			end
		end

		OpenName = nil
		ShowGrid(true)
		return false
	end

	ShowGrid(true)

	return Doc
end

return DocPage
