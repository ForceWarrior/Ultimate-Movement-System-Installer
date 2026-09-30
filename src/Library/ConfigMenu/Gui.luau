--// [Variables]
local Base = Color3.fromRGB(34, 32, 30)
local Panel = Color3.fromRGB(26, 24, 22)
local Raised = Color3.fromRGB(50, 48, 46)
local Zebra = Color3.fromRGB(40, 38, 36)
local Sunken = Color3.fromRGB(22, 20, 18)
local Accent = Color3.fromRGB(240, 130, 20)
local Ink = Color3.fromRGB(20, 20, 20)
local Text = Color3.fromRGB(234, 234, 234)
local BodyText = Color3.fromRGB(218, 218, 218)
local Muted = Color3.fromRGB(178, 178, 178)
local Font = Enum.Font.FredokaOne

--// [Do not go past this point]

local function Within(ParentWidth, ParentHeight)
	return function(X, Y)
		return UDim2.fromScale(X / ParentWidth, Y / ParentHeight)
	end
end

local Window = Within(900, 560)
local Bar = Within(900, 40)
local Buttons = Within(400, 26)
local Find = Within(200, 40)
local Side = Within(200, 480)
local Crumbs = Within(668, 28)
local Output = Within(668, 368)
local Strip = Within(668, 92)
local Row = Within(668, 30)
local Lines = Within(200, 208)

local function New(Class, Props, Parent)
	local Item = Instance.new(Class)
	for Key, Value in Props do Item[Key] = Value end
	Item.Parent = Parent
	return Item
end

local function Rounded(Item, Fraction)
	New("UICorner", { CornerRadius = UDim.new(Fraction, 0) }, Item)
	return Item
end

local function Pad(Item, Left, Top)
	New("UIPadding", { PaddingLeft = UDim.new(Left, 0), PaddingRight = UDim.new(Left, 0), PaddingTop = UDim.new(Top, 0), PaddingBottom = UDim.new(Top, 0) }, Item)
	return Item
end

local function Sized(Item, Largest)
	Item.TextScaled = true
	New("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = math.round(Largest * 1.4) }, Item)
	return Item
end

local function Label(Name, Parent, Props)
	Props.Name = Name
	Props.BackgroundTransparency = 1
	Props.Font = Font
	Props.TextColor3 = Props.TextColor3 or Text
	Props.TextXAlignment = Props.TextXAlignment or Enum.TextXAlignment.Left
	Props.TextTruncate = Props.TextTruncate or Enum.TextTruncate.AtEnd
	Props.Text = Props.Text or ""
	local Largest = Props.TextSize or 15
	Props.TextSize = nil
	return Sized(New("TextLabel", Props, Parent), Largest)
end

local function Button(Name, Parent, Props, Corner)
	Props.Name = Name
	Props.BackgroundColor3 = Props.BackgroundColor3 or Raised
	Props.BorderSizePixel = 0
	Props.Font = Font
	Props.TextColor3 = Props.TextColor3 or Text
	Props.AutoButtonColor = true
	local Largest = Props.TextSize or 15
	Props.TextSize = nil
	return Rounded(Sized(New("TextButton", Props, Parent), Largest), Corner or 0.23)
end

local function Word(Name, Parent, Props)
	Props.BackgroundColor3 = Props.BackgroundColor3 or Panel
	Props.TextColor3 = Props.TextColor3 or Muted
	return Button(Name, Parent, Props)
end

local function Field(Name, Parent, Props, Inset)
	Props.Name = Name
	Props.BackgroundColor3 = Sunken
	Props.BorderSizePixel = 0
	Props.Font = Font
	Props.TextColor3 = Text
	Props.ClearTextOnFocus = false
	Props.TextXAlignment = Props.TextXAlignment or Enum.TextXAlignment.Left
	Props.Text = ""
	return Pad(Rounded(Sized(New("TextBox", Props, Parent), 15), 0.23), Inset, 0)
end

local function Scroller(Name, Parent, Props)
	Props.Name = Name
	Props.BorderSizePixel = 0
	Props.ScrollBarThickness = 4
	Props.ScrollBarImageColor3 = Muted
	Props.CanvasSize = UDim2.new()
	Props.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Props.Selectable = false
	local Made = New("ScrollingFrame", Props, Parent)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, Made)
	return Made
end

local function Fenced(Item)
	Item.SelectionGroup = true
	Item.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	Item.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	Item.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	Item.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	return Item
end

local function Dot(Parent, Position, Size)
	return Rounded(New("Frame", { Name = "Dot", BackgroundColor3 = Accent, BorderSizePixel = 0, Size = Size, Position = Position, AnchorPoint = Vector2.new(0, 0.5), Visible = false }, Parent), 0.5)
end

local function AtRight(Width, Gap)
	return { Size = Row(Width, 22), Position = UDim2.fromScale(1 - Gap / 668, 0.5), AnchorPoint = Vector2.new(1, 0.5) }
end

local Gui = {}

function Gui.Window()
	local Screen = New("ScreenGui", { Name = "MovementConfigMenu", Enabled = false, ResetOnSpawn = false, DisplayOrder = 50, IgnoreGuiInset = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, nil)
	local Frame = Fenced(Rounded(New("Frame", { Name = "Window", BackgroundColor3 = Base, BorderSizePixel = 0, Active = true, ClipsDescendants = true, Size = UDim2.fromScale(0.96, 0.8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5) }, Screen), 0.018))
	Frame:SetAttribute("TouchSize", UDim2.fromScale(0.98, 0.96))
	New("UIAspectRatioConstraint", { AspectRatio = 900 / 560, AspectType = Enum.AspectType.FitWithinMaxSize }, Frame)
	New("UIScale", { Scale = 1 }, Frame)

	local Title = New("Frame", { Name = "Title", BackgroundColor3 = Panel, BorderSizePixel = 0, Size = Window(900, 40) }, Frame)
	Label("Caption", Title, { Text = "Movement config", TextSize = 18, Size = Bar(300, 40), Position = Bar(16, 0) })
	local Holder = New("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = Bar(400, 26), Position = UDim2.fromScale(1 - 10 / 900, 0.5), AnchorPoint = Vector2.new(1, 0.5) }, Title)
	New("UIListLayout", { Padding = UDim.new(4 / 400, 0), FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, Holder)
	Word("Changes", Holder, { Text = "Changes", Size = Buttons(96, 26), LayoutOrder = 1 })
	Word("Validate", Holder, { Text = "Validate", Size = Buttons(80, 26), LayoutOrder = 2 })

	local Reload = Button("Reload", Holder, { Text = "Reload", Size = Buttons(80, 26), LayoutOrder = 3 })
	Reload:SetAttribute("Idle", Raised)
	Reload:SetAttribute("Pending", Accent)
	Reload:SetAttribute("IdleText", Text)
	Reload:SetAttribute("PendingText", Ink)
	Word("Close", Holder, { Text = "Close", Size = Buttons(64, 26), LayoutOrder = 4 })

	local Finder = New("Frame", { Name = "Find", BackgroundColor3 = Panel, BorderSizePixel = 0, Size = Window(200, 40), Position = Window(0, 40) }, Frame)
	local Search = Field("Search", Finder, { Size = Find(184, 28), Position = Find(8, 6), PlaceholderText = "Search settings", PlaceholderColor3 = Muted }, 8 / 184)
	Search:FindFirstChildOfClass("UIPadding").PaddingRight = UDim.new(32 / 184, 0)
	Word("ClearSearch", Finder, { Text = "x", Size = Find(24, 24), Position = UDim2.fromScale(188 / 200, 0.5), AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = Sunken, ZIndex = 2, Visible = false })

	local Blocks = Scroller("Blocks", Frame, { BackgroundColor3 = Panel, Size = Window(200, 480), Position = Window(0, 80) })
	Blocks:SetAttribute("TouchHeight", 44 / 480)

	local Trail = New("Frame", { Name = "Crumbs", BackgroundTransparency = 1, Size = Window(668, 28), Position = Window(216, 48) }, Frame)
	New("UIListLayout", { Padding = UDim.new(8 / 668, 0), FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, Trail)
	Word("Up", Trail, { Text = "< Back", Size = Crumbs(66, 26), LayoutOrder = 1, BackgroundColor3 = Base })
	Label("Path", Trail, { Size = Crumbs(594, 28), LayoutOrder = 99 })

	local Rows = Scroller("Rows", Frame, { BackgroundTransparency = 1, Size = Window(668, 368), Position = Window(216, 84) })
	Rows:SetAttribute("TouchHeight", 48 / 368)

	local Report = New("Frame", { Name = "Output", BackgroundTransparency = 1, Size = Window(668, 368), Position = Window(216, 84), Visible = false }, Frame)
	Label("Heading", Report, { TextSize = 18, Size = Output(480, 26), Position = Output(0, 2) })
	Word("Select", Report, { Text = "Select all", Size = Output(90, 26), Position = UDim2.fromScale(1 - 74 / 668, 2 / 368), AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Base })
	Word("Dismiss", Report, { Text = "< Back", Size = Output(66, 26), Position = UDim2.fromScale(1, 2 / 368), AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Base })
	local Scroll = Rounded(Scroller("Scroll", Report, { BackgroundColor3 = Panel, Size = Output(668, 330), Position = Output(0, 38) }), 0.02)
	Pad(Scroll, 10 / 668, 8 / 330)
	New("TextBox", { Name = "Text", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Font, TextSize = 14, TextColor3 = BodyText, MultiLine = true, TextEditable = false, ClearTextOnFocus = false, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "" }, Scroll)

	local Info = Rounded(New("Frame", { Name = "Info", BackgroundColor3 = Panel, BorderSizePixel = 0, Size = Window(668, 92), Position = Window(216, 460) }, Frame), 0.08)
	Label("Setting", Info, { TextSize = 15, Size = Strip(510, 20), Position = Strip(10, 6) })
	Word("More", Info, { Text = "More", Size = Strip(56, 20), Position = UDim2.fromScale(1 - 80 / 668, 6 / 92), AnchorPoint = Vector2.new(1, 0), Visible = false })
	Word("Revert", Info, { Text = "Revert", Size = Strip(64, 20), Position = UDim2.fromScale(1 - 10 / 668, 6 / 92), AnchorPoint = Vector2.new(1, 0), Visible = false })
	local Facts = Label("Facts", Info, { TextSize = 12, TextColor3 = Muted, Size = Strip(648, 18), Position = Strip(10, 28) })
	Facts:SetAttribute("Plain", Muted)
	Facts:SetAttribute("Warn", Accent)
	Label("Summary", Info, { TextSize = 12, TextColor3 = BodyText, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top, Size = Strip(648, 38), Position = Strip(10, 50) })

	local Picker = Fenced(Rounded(Scroller("Picker", Frame, { BackgroundColor3 = Raised, Size = Window(200, 208), Visible = false, ZIndex = 5 }), 0.03))
	Picker:SetAttribute("Full", Picker.Size)
	return Screen
end

local function RowOf(Name, Parent, ControlLeft)
	local Made = New("Frame", { Name = Name, BackgroundColor3 = Zebra, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 30 / 368) }, Parent)
	Made:SetAttribute("Plain", Zebra)
	Made:SetAttribute("Picked", Raised)
	New("TextButton", { Name = "Hit", Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Selectable = false, Size = UDim2.fromScale(1, 1), ZIndex = 0 }, Made)
	Dot(Made, Row(5, 15), Row(6, 6))
	Button("Remove", Made, { Text = "x", TextColor3 = Muted, Size = Row(22, 22), Position = Row(14, 15), AnchorPoint = Vector2.new(0, 0.5), Visible = false })
	local Key = Label("Key", Made, { Size = UDim2.fromScale((ControlLeft - 24) / 668, 18 / 30), Position = UDim2.fromScale(16 / 668, 0.5), AnchorPoint = Vector2.new(0, 0.5), TextColor3 = BodyText })
	Key:SetAttribute("Shifted", UDim2.fromScale(44 / 668, 0.5))
	return Made
end

function Gui.Templates()
	local Folder = Instance.new("Folder")
	Folder.Name = "Templates"

	local Section = Label("Section", Folder, { Text = "SECTION", TextSize = 12, TextColor3 = Muted, Size = Side(200, 28), TextYAlignment = Enum.TextYAlignment.Bottom })
	New("UIPadding", { PaddingLeft = UDim.new(16 / 200, 0), PaddingBottom = UDim.new(4 / 28, 0) }, Section)

	local Block = Sized(New("TextButton", { Name = "Block", Text = "Block", BackgroundColor3 = Panel, BorderSizePixel = 0, Font = Font, TextColor3 = BodyText, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, AutoButtonColor = true, Size = Side(200, 30) }, Folder), 15)
	New("UIPadding", { PaddingLeft = UDim.new(16 / 200, 0), PaddingRight = UDim.new(36 / 200, 0) }, Block)
	Block:SetAttribute("Plain", Panel)
	Block:SetAttribute("Picked", Raised)

	New("Frame", { Name = "Mark", BackgroundColor3 = Accent, BorderSizePixel = 0, Size = UDim2.fromScale(3 / 148, 1), Position = UDim2.fromScale(-16 / 148, 0), Visible = false }, Block)
	Label("Count", Block, { TextSize = 12, TextColor3 = Accent, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.fromScale(28 / 148, 20 / 30), Position = UDim2.fromScale(1 + 32 / 148, 0.5), AnchorPoint = Vector2.new(1, 0.5), Visible = false })

	local Crumb = Word("Crumb", Folder, { Text = "Crumb", Size = Crumbs(112, 26), BackgroundColor3 = Base })
	Crumb:SetAttribute("Plain", Muted)
	Crumb:SetAttribute("Here", Text)

	local Heading = Sized(New("TextButton", { Name = "Heading", Text = "HEADING", BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Font = Font, TextColor3 = Muted, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.fromScale(1, 26 / 368) }, Folder), 12)
	New("UIPadding", { PaddingLeft = UDim.new(16 / 668, 0), PaddingRight = UDim.new(36 / 668, 0) }, Heading)
	Heading:SetAttribute("Plain", Muted)
	Heading:SetAttribute("Link", BodyText)
	Heading:SetAttribute("Warn", Accent)
	Label("Arrow", Heading, { Text = ">", TextSize = 12, TextColor3 = Muted, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(20 / 616, 1), Position = UDim2.fromScale(1 + 28 / 616, 0), AnchorPoint = Vector2.new(1, 0), Visible = false })

	local ToggleRow = RowOf("ToggleRow", Folder, 612)
	local Toggle = Button("Toggle", ToggleRow, { Text = "", Size = Row(40, 20), Position = UDim2.fromScale(1 - 16 / 668, 0.5), AnchorPoint = Vector2.new(1, 0.5) }, 0.5)
	Toggle:SetAttribute("Off", Raised)
	Toggle:SetAttribute("On", Accent)
	Toggle:SetAttribute("KnobOff", Muted)
	Toggle:SetAttribute("KnobOn", Ink)
	Toggle:SetAttribute("OffAt", UDim2.fromScale(3 / 40, 0.5))
	Toggle:SetAttribute("OnAt", UDim2.fromScale(1 - 3 / 40, 0.5))
	Rounded(New("Frame", { Name = "Knob", BackgroundColor3 = Muted, BorderSizePixel = 0, Size = UDim2.fromScale(14 / 40, 14 / 20), Position = UDim2.fromScale(3 / 40, 0.5), AnchorPoint = Vector2.new(0, 0.5) }, Toggle), 0.5)

	local NumberRow = RowOf("NumberRow", Folder, 482)
	local Minus = AtRight(26, 160)
	Minus.Text = "-"
	Button("Minus", NumberRow, Minus)
	local Amount = AtRight(110, 46)
	Amount.TextXAlignment = Enum.TextXAlignment.Center
	Field("Field", NumberRow, Amount, 8 / 110)
	local Plus = AtRight(26, 16)
	Plus.Text = "+"
	Button("Plus", NumberRow, Plus)

	local Typed = Field("Field", RowOf("TextRow", Folder, 452), AtRight(200, 16), 8 / 200)
	Rounded(New("Frame", { Name = "Swatch", BorderSizePixel = 0, Size = UDim2.fromScale(16 / 184, 14 / 22), Position = UDim2.fromScale(1, 0.5), AnchorPoint = Vector2.new(1, 0.5), Visible = false }, Typed), 0.3)

	local Pick = AtRight(200, 16)
	Pick.Text = "Key"
	Button("Pick", RowOf("KeyRow", Folder, 452), Pick)

	local Choose = AtRight(200, 16)
	Choose.Text = "Choice"
	local Chooser = Button("Choose", RowOf("ChoiceRow", Folder, 452), Choose)
	Label("Arrow", Chooser, { Text = "v", TextSize = 12, TextColor3 = Muted, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(20 / 200, 1), Position = UDim2.fromScale(1, 0), AnchorPoint = Vector2.new(1, 0) })

	local Open = AtRight(200, 16)
	Open.Text = "0 entries  >"
	Button("Open", RowOf("TableRow", Folder, 452), Open)

	local Note = AtRight(200, 16)
	Note.TextColor3 = Muted
	Label("Note", RowOf("InfoRow", Folder, 452), Note)

	local Add = AtRight(200, 16)
	Add.Text = "+ Add"
	Button("Add", RowOf("AddRow", Folder, 452), Add)

	local ActionRow = RowOf("ActionRow", Folder, 422)
	local Export = AtRight(110, 136)
	Export.Text = "Export"
	Export.BackgroundColor3 = Accent
	Export.TextColor3 = Ink
	Button("Export", ActionRow, Export)
	local RevertAll = AtRight(110, 16)
	RevertAll.Text = "Revert all"
	local Undo = Word("RevertAll", ActionRow, RevertAll)
	Undo:SetAttribute("Plain", Panel)
	Undo:SetAttribute("Armed", Accent)
	Undo:SetAttribute("PlainText", Muted)
	Undo:SetAttribute("ArmedText", Ink)

	local Option = Sized(New("TextButton", { Name = "Option", Text = "Option", BackgroundColor3 = Raised, BorderSizePixel = 0, Font = Font, TextColor3 = BodyText, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, AutoButtonColor = true, Size = Lines(200, 26) }, Folder), 15)
	New("UIPadding", { PaddingLeft = UDim.new(10 / 200, 0) }, Option)
	return Folder
end

return Gui
