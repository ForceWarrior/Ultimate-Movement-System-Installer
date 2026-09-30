local Theme = require(script.Parent.Theme)

local Window = {}
Window.__index = Window

local WidgetId = "UMSInstallerWindow"

function Window.New(PluginHandle, Title, DefaultSize, MinimumSize)
	local self = setmetatable({}, Window)

	local Info = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		DefaultSize.X,
		DefaultSize.Y,
		MinimumSize.X,
		MinimumSize.Y
	)

	local Widget = PluginHandle:CreateDockWidgetPluginGui(WidgetId, Info)
	Widget.Name = WidgetId
	Widget.Title = Title
	Widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local Background = Instance.new("Frame")
	Background.Name = "Background"
	Background.Size = UDim2.fromScale(1, 1)
	Background.BackgroundColor3 = Theme.Background
	Background.BorderSizePixel = 0
	Background.ClipsDescendants = true
	Background.Parent = Widget

	local Content = Instance.new("Frame")
	Content.Name = "Content"
	Content.Size = UDim2.fromScale(1, 1)
	Content.BackgroundTransparency = 1
	Content.ClipsDescendants = true
	Content.Parent = Background

	--// Studio does not always honour the minimum
	local TooSmall = Instance.new("Frame")
	TooSmall.Name = "TooSmall"
	TooSmall.Size = UDim2.fromScale(1, 1)
	TooSmall.BackgroundColor3 = Theme.Background
	TooSmall.BorderSizePixel = 0
	TooSmall.Visible = false
	TooSmall.ZIndex = 40
	TooSmall.Parent = Background

	local Notice = Theme.Label("", 12, Theme.Accent, Theme.MediumFont)
	Notice.Size = UDim2.new(1, -24, 1, -24)
	Notice.Position = UDim2.fromOffset(12, 12)
	Notice.TextWrapped = true
	Notice.TextXAlignment = Enum.TextXAlignment.Center
	Notice.TextYAlignment = Enum.TextYAlignment.Center
	Notice.ZIndex = 41
	Notice.Parent = TooSmall

	local function Measure()
		local Size = Background.AbsoluteSize
		local Small = Size.X < MinimumSize.X or Size.Y < MinimumSize.Y
		TooSmall.Visible = Small
		Content.Visible = not Small
		Theme.Fit(Content, Size)
		if Small then
			Notice.Text = math.floor(Size.X) .. " x " .. math.floor(Size.Y) .. "\n\nDrag the window out to at least " .. MinimumSize.X .. " x " .. MinimumSize.Y
		end
	end

	self.Widget = Widget
	self.Content = Content
	self.Background = Background
	self.Minimum = MinimumSize
	self.Changed = Widget:GetPropertyChangedSignal("Enabled")

	Background:GetPropertyChangedSignal("AbsoluteSize"):Connect(Measure)
	Measure()

	return self
end

function Window:IsOpen()
	return self.Widget.Enabled
end

function Window:Toggle()
	self.Widget.Enabled = not self.Widget.Enabled
end

function Window:Destroy()
	self.Widget:Destroy()
end

return Window
