--// [Modules]
local Theme = require(script.Parent.Theme)
local Content = require(script.Parent.Content)

--// [Variables]
local TabAbout = {}
local ReadableWidth = 900
local Margin = 24
local BarWidth = 4

--// [Do not go past this point]

function TabAbout.Build(Page)
	local Scroll = Instance.new("ScrollingFrame")
	Scroll.Name = "AboutScroll"
	Scroll.Size = UDim2.fromScale(1, 1)
	Scroll.BackgroundTransparency = 1
	Scroll.BorderSizePixel = 0
	Scroll.ScrollBarThickness = BarWidth
	Scroll.ScrollBarImageColor3 = Theme.MutedText
	Scroll.CanvasSize = UDim2.new()
	Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Scroll.Parent = Page
	Theme.Padding(Scroll, Margin)

	local Column = Instance.new("Frame")
	Column.Name = "Column"
	Column.Size = UDim2.new(1, -(Margin * 2 + BarWidth), 0, 0)
	Column.AutomaticSize = Enum.AutomaticSize.Y
	Column.BackgroundTransparency = 1
	Column.Parent = Scroll

	local Cap = Instance.new("UISizeConstraint")
	Cap.MaxSize = Vector2.new(ReadableWidth, math.huge)
	Cap.Parent = Column

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 14)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Column

	for Index, Entry in Content.About do
		local Block = Instance.new("Frame")
		Block.Name = "Block" .. Index
		Block.LayoutOrder = Index
		Block.Size = UDim2.new(1, 0, 0, 0)
		Block.AutomaticSize = Enum.AutomaticSize.Y
		Block.BackgroundTransparency = 1
		Block.Parent = Column

		local BlockLayout = Instance.new("UIListLayout")
		BlockLayout.Padding = UDim.new(0, 5)
		BlockLayout.SortOrder = Enum.SortOrder.LayoutOrder
		BlockLayout.Parent = Block

		local Heading = Theme.Label(Entry.Heading, 15, Theme.Text, Theme.TitleFont)
		Heading.LayoutOrder = 1
		Heading.Size = UDim2.new(1, 0, 0, 0)
		Heading.AutomaticSize = Enum.AutomaticSize.Y
		Heading.Parent = Block

		local Body = Theme.Label(Entry.Body, 13, Theme.BodyText)
		Body.LayoutOrder = 2
		Body.Size = UDim2.new(1, 0, 0, 0)
		Body.AutomaticSize = Enum.AutomaticSize.Y
		Body.TextWrapped = true
		Body.TextYAlignment = Enum.TextYAlignment.Top
		Body.Parent = Block
	end

	return function() end
end

return TabAbout
