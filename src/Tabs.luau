--// [Modules]
local Theme = require(script.Parent.Theme)

--// [Variables]
local Tabs = {}

--// [Do not go past this point]

Tabs.__index = Tabs

local BarHeight = 36

function Tabs.New(Parent, Names)
	local self = setmetatable({}, Tabs)
	self.Buttons = {}
	self.Pages = {}
	self.Refreshers = {}
	self.Order = Names
	self.Active = nil

	local Root = Instance.new("Frame")
	Root.Name = "Tabs"
	Root.Position = UDim2.fromOffset(0, 0)
	Root.Size = UDim2.fromScale(1, 1)
	Root.BackgroundTransparency = 1
	Root.ClipsDescendants = true
	Root.Visible = false
	Root.Parent = Parent
	self.Root = Root

	local Bar = Instance.new("Frame")
	Bar.Name = "Bar"
	Bar.Position = UDim2.fromOffset(0, 0)
	Bar.Size = UDim2.new(1, 0, 0, BarHeight)
	Bar.BackgroundColor3 = Theme.Background
	Bar.BorderSizePixel = 0
	Bar.ClipsDescendants = true
	Bar.Parent = Root

	local Underline = Instance.new("Frame")
	Underline.Name = "Underline"
	Underline.Size = UDim2.new(1, 0, 0, 1)
	Underline.Position = UDim2.new(0, 0, 0, BarHeight - 1)
	Underline.BackgroundColor3 = Theme.Border
	Underline.BorderSizePixel = 0
	Underline.ZIndex = 2
	Underline.Parent = Root

	local Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Bar

	local Body = Instance.new("Frame")
	Body.Name = "Body"
	Body.Position = UDim2.new(0, 0, 0, BarHeight)
	Body.Size = UDim2.new(1, 0, 1, -BarHeight)
	Body.BackgroundTransparency = 1
	Body.Parent = Root
	self.Body = Body

	for Index, Name in Names do
		local Button = Instance.new("TextButton")
		Button.Name = Name
		Button.LayoutOrder = Index
		Button.Size = UDim2.fromOffset(110, BarHeight)
		Button.BackgroundTransparency = 1
		Button.BackgroundColor3 = Theme.Panel
		Button.BorderSizePixel = 0
		Button.Text = Name
		Button.TextSize = Theme.Size(13)
		Button.Font = Theme.MediumFont
		Button.TextColor3 = Theme.MutedText
		Button.AutoButtonColor = false
		Button.Parent = Bar

		local Marker = Instance.new("Frame")
		Marker.Name = "Marker"
		Marker.Size = UDim2.new(1, 0, 0, 2)
		Marker.Position = UDim2.new(0, 0, 1, -2)
		Marker.BackgroundColor3 = Theme.Accent
		Marker.BorderSizePixel = 0
		Marker.Visible = false
		Marker.ZIndex = 2
		Marker.Parent = Button

		local Page = Instance.new("Frame")
		Page.Name = Name .. "Page"
		Page.Size = UDim2.fromScale(1, 1)
		Page.BackgroundTransparency = 1
		Page.Visible = false
		Page.Parent = Body

		self.Buttons[Name] = Button
		self.Pages[Name] = Page

		Button.MouseEnter:Connect(function()
			if self.Active ~= Name then
				Button.TextColor3 = Theme.Accent
			end
		end)
		Button.MouseLeave:Connect(function()
			if self.Active ~= Name then
				Button.TextColor3 = Theme.MutedText
			end
		end)
		Button.Activated:Connect(function()
			self:Select(Name)
		end)
	end

	return self
end

function Tabs:SetRefresh(Name, Fn)
	self.Refreshers[Name] = Fn
end

function Tabs:Select(Name)
	if self.Pages[Name] == nil then return end
	self.Active = Name
	for Other, Button in self.Buttons do
		local IsActive = Other == Name
		Button.BackgroundTransparency = IsActive and 0 or 1
		Button.BackgroundColor3 = Theme.Panel
		Button.TextColor3 = IsActive and Theme.Accent or Theme.MutedText
		Button.Font = IsActive and Theme.TitleFont or Theme.MediumFont
		Button.Marker.Visible = IsActive
		self.Pages[Other].Visible = IsActive
	end

	local Refresh = self.Refreshers[Name]
	if Refresh then
		local Ok, Problem = pcall(Refresh)
		if not Ok then
			warn("[Ultimate Movement System Installer] " .. Name .. " tab: " .. tostring(Problem))
		end
	end
end

function Tabs:Page(Name)
	return self.Pages[Name]
end

function Tabs:Show()
	self.Root.Visible = true
	self:Select(self.Active or self.Order[1])
end

function Tabs:Hide()
	self.Root.Visible = false
end

function Tabs:Destroy()
	self.Root:Destroy()
end

return Tabs
