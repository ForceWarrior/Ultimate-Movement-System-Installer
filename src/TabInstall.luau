--// [Modules]
local Theme = require(script.Parent.Theme)
local Content = require(script.Parent.Content)
local Settings = require(script.Parent.Settings)
local Installer = require(script.Parent.Installer)
local Requirements = require(script.Parent.Requirements)
local KitVersion = require(script.Parent.KitVersion)
local AnimationPanel = require(script.Parent.AnimationPanel)

--// [Variables]
local TabInstall = {}

--// [Do not go past this point]

local function Button(Text, Width, Accent)
	return Theme.Button(Text, Width, 32, Accent)
end

local function Heading(Parent, Order, Text)
	local Label = Theme.Label(Text, 14, Theme.Text, Theme.TitleFont)
	Label.LayoutOrder = Order
	Label.Size = UDim2.new(1, -10, 0, 22)
	Label.Parent = Parent
	return Label
end

function TabInstall.Build(Page, PluginHandle)

	local Overwrite = true

	local Extras = {}

	local Scroll = Instance.new("ScrollingFrame")
	Scroll.Size = UDim2.new(1, 0, 1, -46)
	Scroll.BackgroundTransparency = 1
	Scroll.BorderSizePixel = 0
	Scroll.ScrollBarThickness = 4
	Scroll.ScrollBarImageColor3 = Theme.MutedText
	Scroll.CanvasSize = UDim2.new()
	Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Scroll.Parent = Page
	Theme.Padding(Scroll, 16)

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 6)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Scroll

	local FolderHeading = Heading(Scroll, 1, Content.Install.FolderHeading)

	local PlanHolder = Instance.new("Frame")
	PlanHolder.Name = "Plan"
	PlanHolder.LayoutOrder = 3
	PlanHolder.Size = UDim2.new(1, -10, 0, 0)
	PlanHolder.AutomaticSize = Enum.AutomaticSize.Y
	PlanHolder.BackgroundTransparency = 1
	PlanHolder.Parent = Scroll

	local PlanLayout = Instance.new("UIListLayout")
	PlanLayout.Padding = UDim.new(0, 6)
	PlanLayout.SortOrder = Enum.SortOrder.LayoutOrder
	PlanLayout.Parent = PlanHolder

	local Mine = Theme.Checkbox(Content.Install.Overwrite, 240)
	Mine.LayoutOrder = 4
	Mine.Parent = Scroll
	Theme.SetChecked(Mine, Overwrite)

	local MineNote = Theme.Label(Content.Install.OverwriteNote, 12, Theme.MutedText)
	MineNote.LayoutOrder = 5
	MineNote.Size = UDim2.new(1, -10, 0, 0)
	MineNote.AutomaticSize = Enum.AutomaticSize.Y
	MineNote.TextWrapped = true
	MineNote.TextYAlignment = Enum.TextYAlignment.Top
	MineNote.Parent = Scroll

	local AnimationHeading = Heading(Scroll, 10, Content.Install.AnimationHeading)

	local Holder = Instance.new("Frame")
	Holder.LayoutOrder = 12
	Holder.Size = UDim2.new(1, -10, 0, 440)
	Holder.BackgroundTransparency = 1
	Holder.Parent = Scroll

	local Panel = AnimationPanel.New(Holder, PluginHandle, Page)

	local Footer = Instance.new("Frame")
	Footer.Size = UDim2.new(1, 0, 0, 46)
	Footer.Position = UDim2.new(0, 0, 1, -46)
	Footer.BackgroundColor3 = Theme.Panel
	Footer.BorderSizePixel = 0
	Footer.Parent = Page

	local Status = Theme.Label("", 12, Theme.MutedText)
	Status.Position = UDim2.new(0, 160, 0, 0)
	Status.Size = UDim2.new(1, -172, 1, 0)
	Status.TextWrapped = true
	Status.Parent = Footer

	Footer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local Room = Footer.AbsoluteSize.X / Theme.ScaleOf(Footer) - 160
		Status.Visible = Room > 120
	end)

	local Install = Button(Content.Install.Button, 132, true)
	Install.Position = UDim2.new(0, 16, 0.5, -16)
	Install.Parent = Footer

	local Confirm = Theme.Confirm(Page, 72, Content.Install.ReplaceYes, Content.Install.ReplaceNo)

	local function DrawPlan()
		for _, Child in PlanHolder:GetChildren() do
			if Child:IsA("Frame") then
				Child:Destroy()
			end
		end

		local Package, Plan = Installer.Preview(Extras)
		if not Package then

			local Done = Installer.Installed()
			FolderHeading.Visible = not Done
			PlanHolder.Visible = not Done
			AnimationHeading.Text = Done and Content.Install.AnimationHeadingOnly
				or Content.Install.AnimationHeading
			Status.Text = Done and Content.Install.AlreadyInstalled
				or Content.Install.NoPackage(Settings.Get("PackageName"), table.concat(Settings.SearchIn, ", "))
			Status.TextColor3 = Done and Theme.Success or Theme.Warning
			Install.Visible = false
			Mine.Visible = false
			MineNote.Visible = false
			return
		end
		FolderHeading.Visible = true
		PlanHolder.Visible = true
		AnimationHeading.Text = Content.Install.AnimationHeading
		Install.Visible = true

		local Colliding = Installer.CollisionCount(Plan)
		Mine.Visible = Colliding > 0
		MineNote.Visible = Mine.Visible
		Theme.SetChecked(Mine, Overwrite)

		for Index, Entry in Plan do
			local Row = Instance.new("Frame")
			Row.LayoutOrder = Index
			Row.Size = UDim2.new(1, 0, 0, 40)
			Row.BackgroundColor3 = Theme.Panel
			Row.BorderSizePixel = 0
			Row.Parent = PlanHolder
			Theme.Stroke(Row, Entry.Target and Theme.Border or Theme.Danger)

			local Home = Entry.Optional and (Entry.Path .. ", from " .. Entry.Optional.Name) or Entry.Path
			local Where = Theme.Label(Home, 13, Entry.Target and Theme.Text or Theme.Danger, Theme.MediumFont)
			Where.Position = UDim2.new(0, 10, 0, 5)
			Where.Size = UDim2.new(1, -20, 0, 16)
			Where.Parent = Row

			local Detail = Content.Install.PlanUnresolved
			if Entry.Target then
				Detail = Content.Install.PlanRow(Entry.Count, #Entry.Collisions > 0 and Content.Install.PlanCollides(#Entry.Collisions) or "")
			end
			local Info = Theme.Label(Detail, 12, Theme.MutedText)
			Info.Position = UDim2.new(0, 10, 0, 21)
			Info.Size = UDim2.new(1, -20, 0, 14)
			Info.Parent = Row
		end

		local Extra = #Plan
		for _, Optional in Requirements.Optionals(Package) do
			Extra += 1
			local Row = Instance.new("Frame")
			Row.LayoutOrder = Extra
			Row.Size = UDim2.new(1, 0, 0, 44)
			Row.BackgroundColor3 = Theme.Panel
			Row.BorderSizePixel = 0
			Row.Parent = PlanHolder
			Theme.Stroke(Row, Theme.Border)

			local Pretty = Optional.Name:gsub("_Optional$", ""):gsub("_", " ")
			local Tick = Theme.Checkbox(Content.Install.OptionalTick(Pretty), 300)
			Tick.Position = UDim2.new(0, 10, 0, 4)
			Tick.Size = UDim2.new(1, -20, 0, 20)
			Tick.Parent = Row
			Theme.SetChecked(Tick, Extras[Optional.Name] == true)
			Tick.Activated:Connect(function()
				Extras[Optional.Name] = not Extras[Optional.Name] or nil
				DrawPlan()
			end)

			local Info = Theme.Label(Content.Install.OptionalNote(Optional.Count), 12, Theme.MutedText)
			Info.Position = UDim2.new(0, 32, 0, 25)
			Info.Size = UDim2.new(1, -42, 0, 14)
			Info.Parent = Row
		end

		Status.Text = Content.Install.Ready(Package:GetFullName(), #Plan, Colliding)
		if Installer.Installed() then
			Status.Text = Status.Text .. "  |  " .. Content.Install.Versions((KitVersion.Live()), (KitVersion.Package(Package)))
		end
		Status.TextColor3 = Colliding > 0 and Theme.Warning or Theme.Success
	end

	local function DrawAnimations()
		local Ok, Problem = Panel:Load()
		if not Ok then
			Panel.Summary.Text = Problem
			Panel.Summary.TextColor3 = Theme.Warning
			Panel.Rows = {}
		else
			Panel.Summary.TextColor3 = Theme.MutedText
		end
		Panel:Render()
	end

	local function RunInstall(Trailer)
		local Ok, Log = Installer.Run(Overwrite, Extras)
		if Trailer then
			table.insert(Log, Trailer)
		end
		Status.Text = table.concat(Log, "  |  ")
		Status.TextColor3 = Ok and Theme.Success or Theme.Warning
		DrawPlan()
		DrawAnimations()
	end

	local function AskThenInstall(Trailer)
		local Package = Installer.Preview(Extras)
		if not (Package and Installer.Installed()) then
			RunInstall(Trailer)
			return
		end

		local Have = KitVersion.Live()
		local Want = KitVersion.Package(Package)
		local Verdict = KitVersion.Compare(Have, Want)
		local Question = Content.Install.ReplaceUnknown
		if Verdict == "different" then
			Question = Content.Install.ReplaceDifferent(Have, Want)
		elseif Verdict == "same" then
			Question = Content.Install.ReplaceSame(Have)
		end

		Confirm.Show(Content.Install.ReplaceHeading, Question, function()
			RunInstall(Trailer)
		end)
	end

	Mine.Activated:Connect(function()
		Overwrite = not Overwrite
		DrawPlan()
	end)
	Install.Activated:Connect(function()
		AskThenInstall(nil)
	end)

	local function Refresh()

		if Panel.Busy then
			return
		end
		DrawPlan()
		DrawAnimations()
	end

	Refresh()
	return Refresh
end

return TabInstall
