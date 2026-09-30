--// [Variables]
local Theme = {}

--// [Do not go past this point]

Theme.Background = Color3.fromRGB(46, 46, 46)
Theme.Panel = Color3.fromRGB(37, 37, 37)
Theme.Raised = Color3.fromRGB(56, 56, 56)
Theme.Hover = Color3.fromRGB(66, 66, 66)
Theme.Border = Color3.fromRGB(26, 26, 26)
Theme.CardEdge = Color3.fromRGB(26, 26, 26)

Theme.Accent = Color3.fromRGB(240, 130, 20)
Theme.AccentHover = Color3.fromRGB(255, 155, 60)
Theme.AccentPressed = Color3.fromRGB(200, 100, 10)
Theme.AccentFill = Color3.fromRGB(90, 55, 25)
Theme.AccentInk = Color3.fromRGB(20, 20, 20)

Theme.Text = Color3.fromRGB(234, 234, 234)
Theme.BodyText = Color3.fromRGB(218, 218, 218)
Theme.MutedText = Color3.fromRGB(178, 178, 178)
Theme.Danger = Color3.fromRGB(214, 104, 96)
Theme.Success = Color3.fromRGB(124, 186, 110)
Theme.Warning = Color3.fromRGB(220, 176, 84)

Theme.TitleFont = Enum.Font.SourceSansSemibold
Theme.BodyFont = Enum.Font.SourceSans
Theme.MediumFont = Enum.Font.SourceSans

Theme.Sizes = { [10] = 13, [11] = 13, [12] = 14, [13] = 15, [14] = 16, [15] = 17, [16] = 18, [17] = 19, [20] = 22, [22] = 24 }

function Theme.Size(Size)
	return Theme.Sizes[Size] or Size
end

function Theme.Fit(Content, Size)
	local Scale = Content:FindFirstChildOfClass("UIScale")
	if not Scale then
		Scale = Instance.new("UIScale")
		Scale.Parent = Content
	end
	local Factor = math.clamp(math.min(Size.X / 820, Size.Y / 560), 1, 2.2)
	Scale.Scale = Factor
	Content.Size = UDim2.fromScale(1 / Factor, 1 / Factor)
end

function Theme.ScaleOf(Item)
	local Node = Item
	while Node do
		local Scale = Node:FindFirstChildOfClass("UIScale")
		if Scale then
			return Scale.Scale
		end
		Node = Node.Parent
	end
	return 1
end

function Theme.Stroke(Target, Color, Thickness)
	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color or Theme.Border
	Stroke.Thickness = Thickness or 1
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = Target
	return Stroke
end

function Theme.Padding(Target, All)
	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0, All)
	Padding.PaddingBottom = UDim.new(0, All)
	Padding.PaddingLeft = UDim.new(0, All)
	Padding.PaddingRight = UDim.new(0, All)
	Padding.Parent = Target
	return Padding
end

function Theme.Button(Text, Width, Height, Accent)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.fromOffset(Width, Height or 26)
	Button.BorderSizePixel = 0
	Button.Text = Text
	Button.TextSize = Theme.Size(14)
	Button.AutoButtonColor = false
	Button.Font = Accent and Theme.TitleFont or Theme.BodyFont

	local Base = Accent and Theme.Accent or Theme.Raised
	local Over = Accent and Theme.AccentHover or Theme.Hover
	local Down = Accent and Theme.AccentPressed or Theme.Panel
	local Ink = Accent and Theme.AccentInk or Theme.Text

	Button.BackgroundColor3 = Base
	Button.TextColor3 = Ink
	local Edge = Theme.Stroke(Button, Theme.Border)

	Button:SetAttribute("BaseColor", Base)
	Button:SetAttribute("OverColor", Over)
	Button:SetAttribute("InkColor", Ink)
	Button:SetAttribute("EdgeColor", Edge.Color)

	Button.MouseEnter:Connect(function()
		if Button:GetAttribute("Locked") then return end
		Button.BackgroundColor3 = Over
	end)
	Button.MouseLeave:Connect(function()
		if Button:GetAttribute("Locked") then return end
		Button.BackgroundColor3 = Base
	end)
	Button.MouseButton1Down:Connect(function()
		if Button:GetAttribute("Locked") then return end
		Button.BackgroundColor3 = Down
	end)
	Button.MouseButton1Up:Connect(function()
		if Button:GetAttribute("Locked") then return end
		Button.BackgroundColor3 = Over
	end)

	return Button
end

function Theme.ScrollInset(Scroll, Room)
	local Inset = Instance.new("UIPadding")
	local Gap = UDim.new(0, Room or 4)
	Inset.PaddingTop = Gap
	Inset.PaddingBottom = Gap
	Inset.PaddingLeft = Gap

	Inset.PaddingRight = UDim.new(0, (Room or 4) + Scroll.ScrollBarThickness)
	Inset.Parent = Scroll
	return Inset
end

function Theme.TrashButton(Parent, Span)
	local Size = Span or 18
	local Button = Instance.new("TextButton")
	Button.Name = "Trash"
	Button.Size = UDim2.fromOffset(Size, Size)
	Button.BackgroundTransparency = 1
	Button.Text = "X"
	Button.TextSize = Size
	Button.Font = Theme.TitleFont
	Button.TextColor3 = Theme.MutedText
	Button.AutoButtonColor = false
	Button.Parent = Parent

	Button.MouseEnter:Connect(function()
		Button.TextColor3 = Theme.Danger
	end)
	Button.MouseLeave:Connect(function()
		Button.TextColor3 = Theme.MutedText
	end)

	return Button
end

function Theme.Confirm(Parent, Depth, YesText, NoText)
	local Layer = Depth or 74
	local Confirm = {}
	local Answer = nil

	local Veil = Instance.new("TextButton")
	Veil.Name = "Confirm"
	Veil.Size = UDim2.fromScale(1, 1)
	Veil.BackgroundColor3 = Theme.Background
	Veil.BackgroundTransparency = 0.15
	Veil.BorderSizePixel = 0
	Veil.Text = ""
	Veil.AutoButtonColor = false
	Veil.Modal = true
	Veil.Visible = false
	Veil.ZIndex = Layer
	Veil.Parent = Parent

	local Card = Instance.new("Frame")
	Card.AnchorPoint = Vector2.new(0.5, 0.5)
	Card.Position = UDim2.fromScale(0.5, 0.5)
	Card.Size = UDim2.fromOffset(540, 168)
	Card.BackgroundColor3 = Theme.Panel
	Card.BorderSizePixel = 0
	Card.ZIndex = Layer + 1
	Card.Parent = Veil
	Theme.Stroke(Card, Theme.Accent)

	local Title = Theme.Label("", 17, Theme.Accent, Theme.TitleFont)
	Title.Position = UDim2.fromOffset(20, 18)
	Title.Size = UDim2.new(1, -40, 0, 22)
	Title.ZIndex = Layer + 2
	Title.Parent = Card

	local PickerRow = Instance.new("Frame")
	PickerRow.Position = UDim2.fromOffset(20, 46)
	PickerRow.Size = UDim2.new(1, -40, 0, 26)
	PickerRow.BackgroundTransparency = 1
	PickerRow.Visible = false
	PickerRow.ZIndex = Layer + 2
	PickerRow.Parent = Card

	local PickerLabel = Theme.Label("", 13, Theme.MutedText)
	PickerLabel.Size = UDim2.new(0, 150, 1, 0)
	PickerLabel.ZIndex = Layer + 2
	PickerLabel.Parent = PickerRow

	local PickerHolder = Instance.new("Frame")
	PickerHolder.Position = UDim2.fromOffset(150, 0)
	PickerHolder.Size = UDim2.new(1, -150, 1, 0)
	PickerHolder.BackgroundTransparency = 1
	PickerHolder.ZIndex = Layer + 2
	PickerHolder.Parent = PickerRow

	local Picker = Theme.Dropdown(PickerHolder, Parent, "", 270, 26, Layer + 6)
	Picker.Button.ZIndex = Layer + 3
	for _, Child in Picker.Button:GetChildren() do
		if Child:IsA("GuiObject") then
			Child.ZIndex = Layer + 4
		end
	end

	local Body = Theme.Label("", 15, Theme.BodyText)
	Body.LineHeight = 1.2
	Body.Position = UDim2.fromOffset(20, 46)
	Body.Size = UDim2.new(1, -40, 0, 0)
	Body.AutomaticSize = Enum.AutomaticSize.Y
	Body.TextWrapped = true
	Body.TextYAlignment = Enum.TextYAlignment.Top
	Body.ZIndex = Layer + 2
	Body.Parent = Card

	local Alert = Theme.Label("", 15, Theme.Danger)
	Alert.LineHeight = 1.2
	Alert.Position = UDim2.fromOffset(20, 46)
	Alert.Size = UDim2.new(1, -40, 0, 0)
	Alert.AutomaticSize = Enum.AutomaticSize.Y
	Alert.TextWrapped = true
	Alert.TextYAlignment = Enum.TextYAlignment.Top
	Alert.Visible = false
	Alert.ZIndex = Layer + 2
	Alert.Parent = Card

	local Yes = Theme.Button(YesText or "Yes, delete it", 168, 28, true)
	Yes.AnchorPoint = Vector2.new(1, 0)
	Yes.Position = UDim2.new(1, -20, 1, -44)
	Yes.ZIndex = Layer + 2
	Yes.Parent = Card

	local No = Theme.Button(NoText or "Keep it", 100, 28, false)
	No.AnchorPoint = Vector2.new(1, 0)
	No.Position = UDim2.new(1, -196, 1, -44)
	No.ZIndex = Layer + 2
	No.Parent = Card

	local function Fit()
		local Top = PickerRow.Visible and 82 or 46
		Body.Position = UDim2.fromOffset(20, Top)
		local Factor = Theme.ScaleOf(Body)
		local Under = Top + Body.AbsoluteSize.Y / Factor
		local Extra = 0
		if Alert.Visible then
			Alert.Position = UDim2.fromOffset(20, Under + 10)
			Extra = 10 + Alert.AbsoluteSize.Y / Factor
		end
		Card.Size = UDim2.fromOffset(540, math.clamp(Under + Extra + 56, 168, 560))
	end
	Body:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)
	Alert:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)

	function Confirm.SetText(Text, Warning)
		Body.Text = Text
		Alert.Visible = type(Warning) == "string" and Warning ~= ""
		Alert.Text = Alert.Visible and Warning or ""
		Fit()
	end

	function Confirm.Show(Heading, Text, OnYes, Warning, Choice)
		Title.Text = Heading
		PickerRow.Visible = Choice ~= nil
		if Choice then
			PickerLabel.Text = Choice.Label or ""
			Picker.OnPick = nil
			Picker.SetOptions(Choice.Options or {})
			Picker.Index = Choice.Index or 1
			Picker.SetLocked(false)
			Picker.OnPick = Choice.OnPick
		end
		Answer = OnYes
		Veil.Visible = true
		Confirm.SetText(Text, Warning)
	end

	function Confirm.Hide()
		Veil.Visible = false
		Answer = nil
		Picker.SetLocked(true)
		Picker.SetLocked(false)
	end

	Yes.Activated:Connect(function()
		local Run = Answer
		Confirm.Hide()
		if Run then
			Run()
		end
	end)
	No.Activated:Connect(Confirm.Hide)

	Confirm.Veil = Veil
	return Confirm
end

function Theme.SetLocked(Button, State)
	if not Button then return end
	Button:SetAttribute("Locked", State or nil)
	Button.BackgroundColor3 = State and Theme.Background or (Button:GetAttribute("BaseColor") or Theme.Raised)
	Button.TextColor3 = State and Theme.MutedText or (Button:GetAttribute("InkColor") or Theme.Text)
	local Edge = Button:FindFirstChildOfClass("UIStroke")
	if Edge then
		Edge.Color = State and Theme.Border or (Button:GetAttribute("EdgeColor") or Theme.Border)
	end
end

function Theme.Checkbox(Text, Width)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.fromOffset(Width or 160, 22)
	Button.BackgroundTransparency = 1
	Button.Text = ""
	Button.AutoButtonColor = false

	local Box = Instance.new("Frame")
	Box.Name = "Box"
	Box.Size = UDim2.fromOffset(14, 14)
	Box.Position = UDim2.fromOffset(0, 4)
	Box.BackgroundColor3 = Theme.Background
	Box.BorderSizePixel = 0
	Box.Parent = Button
	Theme.Stroke(Box, Theme.Border)

	local Fill = Instance.new("Frame")
	Fill.Name = "Fill"
	Fill.Size = UDim2.fromScale(0.6, 0.6)
	Fill.Position = UDim2.fromScale(0.2, 0.2)
	Fill.BackgroundColor3 = Theme.Accent
	Fill.BorderSizePixel = 0
	Fill.Visible = false
	Fill.Parent = Box

	local Label = Theme.Label(Text, 12, Theme.MutedText)
	Label.Name = "Label"
	Label.Position = UDim2.fromOffset(22, 0)
	Label.Size = UDim2.new(1, -22, 1, 0)
	Label.Parent = Button

	return Button
end

function Theme.SetChecked(Button, State)
	local Box = Button and Button:FindFirstChild("Box")
	local Fill = Box and Box:FindFirstChild("Fill")
	local Label = Button and Button:FindFirstChild("Label")
	if Fill then
		Fill.Visible = State == true
	end
	if Label then
		Label.TextColor3 = State and Theme.Text or Theme.MutedText
	end
end

function Theme.Group(Parent, Title, Inset)
	local Frame = Instance.new("Frame")
	Frame.BackgroundColor3 = Theme.Panel
	Frame.BorderSizePixel = 0
	Frame.Parent = Parent
	Theme.Stroke(Frame, Theme.Border)

	local Legend = Theme.Label(Title, 12, Theme.MutedText, Theme.TitleFont)
	Legend.Name = "Legend"
	Legend.BackgroundTransparency = 1
	Legend.Position = UDim2.fromOffset(10, 5)
	Legend.Size = UDim2.new(1, -20, 0, 17)
	Legend.ZIndex = 3
	Legend.Parent = Frame

	local Body = Instance.new("Frame")
	Body.Name = "Body"
	Body.Position = UDim2.fromOffset(0, 22)
	Body.Size = UDim2.new(1, 0, 1, -22)
	Body.BackgroundTransparency = 1
	Body.Parent = Frame
	Theme.Padding(Body, Inset or 10)

	return Frame, Body
end

function Theme.Dropdown(Parent, Overlay, Placeholder, Width, Height, Depth)
	local Control = {}
	Control.Options = {}
	Control.Index = nil

	local Tall = Height or 26

	local Layer = Depth or 60

	local Button = Theme.Button(Placeholder, Width, Tall, false)
	Button.TextXAlignment = Enum.TextXAlignment.Left
	Button.TextColor3 = Theme.MutedText
	Button.Parent = Parent
	Control.Button = Button

	local Inset = Instance.new("UIPadding")
	Inset.PaddingLeft = UDim.new(0, 9)
	Inset.PaddingRight = UDim.new(0, 22)
	Inset.Parent = Button

	local Caret = Theme.Label("v", 10, Theme.Accent, Theme.TitleFont)
	Caret.Size = UDim2.fromOffset(14, Tall)
	Caret.Position = UDim2.new(1, 8, 0, 0)
	Caret.TextXAlignment = Enum.TextXAlignment.Center
	Caret.Parent = Button

	local Blocker = Instance.new("TextButton")
	Blocker.Name = "DropdownBlocker"
	Blocker.Size = UDim2.fromScale(1, 1)
	Blocker.BackgroundTransparency = 1
	Blocker.Text = ""
	Blocker.AutoButtonColor = false
	Blocker.Modal = true
	Blocker.Visible = false
	Blocker.ZIndex = Layer
	Blocker.Parent = Overlay

	local List = Instance.new("ScrollingFrame")
	List.Name = "DropdownList"
	List.BackgroundColor3 = Theme.Panel
	List.BorderSizePixel = 0
	List.ScrollBarThickness = 4
	List.ScrollBarImageColor3 = Theme.MutedText
	List.CanvasSize = UDim2.new()
	List.AutomaticCanvasSize = Enum.AutomaticSize.Y
	List.Visible = false
	List.ZIndex = Layer + 1
	List.Parent = Overlay
	Theme.Stroke(List, Theme.Accent)

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = List

	local Rim = Instance.new("UIPadding")
	Rim.PaddingTop = UDim.new(0, 4)
	Rim.PaddingBottom = UDim.new(0, 4)
	Rim.Parent = List

	local function Close()
		List.Visible = false
		Blocker.Visible = false
	end

	local function Open()
		if #Control.Options == 0 then
			return
		end
		local Factor = Theme.ScaleOf(Overlay)
		local At = (Button.AbsolutePosition - Overlay.AbsolutePosition) / Factor
		local Shown = math.clamp(#Control.Options, 1, 8)
		local High = Shown * 24 + 8
		local Top = At.Y + Button.AbsoluteSize.Y / Factor + 2

		if Top + High > Overlay.AbsoluteSize.Y / Factor and At.Y - High - 2 >= 0 then
			Top = At.Y - High - 2
		end

		List.Position = UDim2.fromOffset(At.X, Top)
		List.Size = UDim2.fromOffset(math.max(Button.AbsoluteSize.X / Factor, 220), High)
		Blocker.Visible = true
		List.Visible = true
	end

	Blocker.Activated:Connect(Close)
	Button.Activated:Connect(function()
		if Button:GetAttribute("Locked") then
			return
		end
		if List.Visible then
			Close()
		else
			Open()
		end
	end)

	local function Paint()
		local Item = Control.Index and Control.Options[Control.Index]
		Button.Text = Item and (Item.Short or Item.Label) or Placeholder
		Button.TextColor3 = Item and Theme.Accent or Theme.MutedText
		Button:SetAttribute("InkColor", Button.TextColor3)
	end

	function Control.SetOptions(Items)
		Control.Options = Items or {}
		Control.Index = nil
		for _, Child in List:GetChildren() do
			if Child:IsA("TextButton") then
				Child:Destroy()
			end
		end
		for Index, Item in Control.Options do
			local Row = Instance.new("TextButton")
			Row.LayoutOrder = Index
			Row.Size = UDim2.new(1, 0, 0, 24)
			Row.BackgroundColor3 = Theme.Raised
			Row.BackgroundTransparency = 1
			Row.BorderSizePixel = 0
			Row.Text = "   " .. Item.Label
			Row.TextSize = Theme.Size(12)
			Row.Font = Theme.BodyFont
			Row.TextColor3 = Theme.Text
			Row.TextXAlignment = Enum.TextXAlignment.Left
			Row.TextTruncate = Enum.TextTruncate.AtEnd
			Row.AutoButtonColor = false
			Row.Parent = List
			Row.MouseEnter:Connect(function()
				Row.BackgroundTransparency = 0
				Row.TextColor3 = Theme.Accent
			end)
			Row.MouseLeave:Connect(function()
				Row.BackgroundTransparency = 1
				Row.TextColor3 = Theme.Text
			end)
			Row.Activated:Connect(function()
				Close()
				Control.Index = Index
				Paint()
				if Control.OnPick then
					Control.OnPick(Index, Item)
				end
			end)
		end
		Paint()
	end

	function Control.Get()
		return Control.Index, Control.Index and Control.Options[Control.Index] or nil
	end

	function Control.Select(Index)
		Control.Index = Control.Options[Index] and Index or nil
		Paint()
	end

	function Control.SetLocked(State)
		Theme.SetLocked(Button, State)
		if State then
			Close()
		else
			Paint()
		end
	end

	Paint()
	return Control
end

function Theme.Sheet(Parent, Depth, Title)
	local Layer = Depth or 30
	local Sheet = {}

	local Veil = Instance.new("TextButton")
	Veil.Name = "Sheet"
	Veil.Size = UDim2.fromScale(1, 1)
	Veil.BackgroundColor3 = Theme.Background
	Veil.BackgroundTransparency = 0.08
	Veil.BorderSizePixel = 0
	Veil.Text = ""
	Veil.AutoButtonColor = false
	Veil.Modal = true
	Veil.Visible = false
	Veil.ZIndex = Layer
	Veil.Parent = Parent

	local Card = Instance.new("Frame")
	Card.AnchorPoint = Vector2.new(0.5, 0.5)
	Card.Position = UDim2.fromScale(0.5, 0.5)
	Card.Size = UDim2.new(1, -70, 1, -50)
	Card.BackgroundColor3 = Theme.Panel
	Card.BorderSizePixel = 0
	Card.ZIndex = Layer + 1
	Card.Parent = Veil
	Theme.Stroke(Card, Theme.Accent)

	local Cap = Instance.new("UISizeConstraint")
	Cap.MaxSize = Vector2.new(760, 480)
	Cap.Parent = Card

	local Heading = Theme.Label(Title, 15, Theme.Accent, Theme.TitleFont)
	Heading.Position = UDim2.fromOffset(18, 14)
	Heading.Size = UDim2.new(1, -130, 0, 22)
	Heading.ZIndex = Layer + 2
	Heading.Parent = Card

	local Shut = Theme.Button("Close", 84, 26, false)
	Shut.AnchorPoint = Vector2.new(1, 0)
	Shut.Position = UDim2.new(1, -18, 0, 12)
	Shut.ZIndex = Layer + 2
	Shut.Parent = Card

	local Body = Instance.new("Frame")
	Body.Name = "Body"
	Body.Position = UDim2.fromOffset(18, 48)
	Body.Size = UDim2.new(1, -36, 1, -66)
	Body.BackgroundTransparency = 1
	Body.ZIndex = Layer + 2
	Body.Parent = Card

	Sheet.Veil = Veil
	Sheet.Card = Card
	Sheet.Body = Body
	Sheet.Heading = Heading
	Sheet.Layer = Layer

	function Sheet.Show()
		Veil.Visible = true
	end

	function Sheet.Hide()
		Veil.Visible = false
	end

	Shut.Activated:Connect(Sheet.Hide)
	return Sheet
end

function Theme.Notice(Parent, Depth, Dismiss)
	local Layer = Depth or 70
	local Notice = {}

	local Veil = Instance.new("TextButton")
	Veil.Name = "Notice"
	Veil.Size = UDim2.fromScale(1, 1)
	Veil.BackgroundColor3 = Theme.Background
	Veil.BackgroundTransparency = 0.15
	Veil.BorderSizePixel = 0
	Veil.Text = ""
	Veil.AutoButtonColor = false
	Veil.Modal = true
	Veil.Visible = false
	Veil.ZIndex = Layer
	Veil.Parent = Parent

	local Card = Instance.new("Frame")
	Card.AnchorPoint = Vector2.new(0.5, 0.5)
	Card.Position = UDim2.fromScale(0.5, 0.5)
	Card.Size = UDim2.fromOffset(380, 168)
	Card.BackgroundColor3 = Theme.Panel
	Card.BorderSizePixel = 0
	Card.ZIndex = Layer + 1
	Card.Parent = Veil
	Theme.Stroke(Card, Theme.Accent)

	local Title = Theme.Label("", 17, Theme.Accent, Theme.TitleFont)
	Title.Position = UDim2.fromOffset(20, 18)
	Title.Size = UDim2.new(1, -40, 0, 22)
	Title.ZIndex = Layer + 2
	Title.Parent = Card

	local Body = Theme.Label("", 14, Theme.BodyText)
	Body.Position = UDim2.fromOffset(20, 46)
	Body.Size = UDim2.new(1, -40, 0, 0)
	Body.AutomaticSize = Enum.AutomaticSize.Y
	Body.TextWrapped = true
	Body.TextYAlignment = Enum.TextYAlignment.Top
	Body.ZIndex = Layer + 2
	Body.Parent = Card

	local Ok = Theme.Button(Dismiss or "OK", 96, 28, true)
	Ok.AnchorPoint = Vector2.new(1, 0)
	Ok.Position = UDim2.new(1, -20, 1, -44)
	Ok.ZIndex = Layer + 2
	Ok.Parent = Card

	local function Fit()
		Card.Size = UDim2.fromOffset(400, math.clamp(46 + Body.AbsoluteSize.Y / Theme.ScaleOf(Body) + 56, 168, 460))
	end
	Body:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)

	function Notice.Show(Heading, Text)
		Title.Text = Heading
		Body.Text = Text
		Veil.Visible = true
		Fit()
	end

	function Notice.Hide()
		Veil.Visible = false
	end

	Ok.Activated:Connect(Notice.Hide)
	Notice.Veil = Veil
	return Notice
end

function Theme.Label(Text, Size, Color, Font)
	local Label = Instance.new("TextLabel")
	Label.BackgroundTransparency = 1
	Label.Text = Text
	Label.TextSize = Theme.Size(Size or 14)
	Label.TextColor3 = Color or Theme.Text
	Label.Font = Font or Theme.MediumFont
	Label.TextXAlignment = Enum.TextXAlignment.Left
	return Label
end

return Theme
