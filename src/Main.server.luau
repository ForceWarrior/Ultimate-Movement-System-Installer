--// [Modules]
local Window = require(script.Parent.Window)
local Requirements = require(script.Parent.Requirements)
local Content = require(script.Parent.Content)
local MainScreen = require(script.Parent.MainScreen)
local Tabs = require(script.Parent.Tabs)
local TabAbout = require(script.Parent.TabAbout)
local TabInstall = require(script.Parent.TabInstall)
local TabPresets = require(script.Parent.TabPresets)
local TabConfig = require(script.Parent.TabConfig)
local TabApi = require(script.Parent.TabApi)
local TabLibrary = require(script.Parent.TabLibrary)

--// [Do not go past this point]

Requirements.Attach(plugin)

local Toolbar = plugin:CreateToolbar(Content.ToolbarName)
local ToggleButton = Toolbar:CreateButton(Content.ButtonLabel, Content.ButtonTooltip, "")
ToggleButton.ClickableWhenViewportHidden = true

local MainWindow = Window.New(plugin, Content.WindowTitle, Vector2.new(820, 560), Vector2.new(620, 460))
local Screen = MainScreen.New(MainWindow.Content, plugin)
local Pages = Tabs.New(MainWindow.Content, Content.TabOrder)

local RefreshAbout = TabAbout.Build(Pages:Page("About"))
local RefreshInstall = TabInstall.Build(Pages:Page("Install"), plugin)
local RefreshPresets = TabPresets.Build(Pages:Page("Presets"), plugin)
local RefreshConfig = TabConfig.Build(Pages:Page("Config"))
local RefreshApi = TabApi.Build(Pages:Page("API"))
local RefreshLibrary = TabLibrary.Build(Pages:Page("Library"))

Pages:SetRefresh("About", RefreshAbout)
Pages:SetRefresh("Install", RefreshInstall)
Pages:SetRefresh("Presets", RefreshPresets)
Pages:SetRefresh("Config", RefreshConfig)
Pages:SetRefresh("API", RefreshApi)
Pages:SetRefresh("Library", RefreshLibrary)

Screen.Ready:Connect(function()
	Pages:Show()
end)

ToggleButton.Click:Connect(function()
	MainWindow:Toggle()
end)

MainWindow.Changed:Connect(function()
	local Open = MainWindow:IsOpen()
	ToggleButton:SetActive(Open)
	if Open then
		Pages:Hide()
		Screen:Reset()
	end
end)

ToggleButton:SetActive(MainWindow:IsOpen())

plugin.Unloading:Connect(function()
	Pages:Destroy()
	Screen:Destroy()
	MainWindow:Destroy()
end)
