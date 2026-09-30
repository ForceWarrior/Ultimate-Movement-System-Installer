--// [Services]
local StarterGui = game:GetService("StarterGui")

--// [Modules]
local Gui = require(script.Gui)

--// [Variables]
local ConfigMenu = {}

--// [Do not go past this point]

ConfigMenu.Folder = "Config Menu"

ConfigMenu.ConfigBlock = { Name = "ConfigMenu", Source = [==[
Config.ConfigMenu = {
	--// [Toggles]
	Enabled = true,
	StudioOnly = true,

	--// [Keys]
	OpenKey = Enum.KeyCode.F2,
	OpenButton = Enum.KeyCode.ButtonSelect,

	--// [Values]
	Scale = 1,
}]==] }

function ConfigMenu.Detect()
	return {}
end

local function Module()
	local Made = Instance.new("ModuleScript")
	Made.Source = require(script.Module)
	Gui.Templates().Parent = Made
	local Docs = Instance.new("ModuleScript")
	Docs.Name = "Docs"
	Docs.Source = require(script.Docs).Source()
	Docs.Parent = Made
	return Made
end

function ConfigMenu.Files(Facts)
	return {
		{ Name = "ConfigMenu", Make = Module, Where = Facts.Kit.Custom },
		{ Name = "MovementConfigMenu", Make = Gui.Window, Where = StarterGui },
	}
end

function ConfigMenu.Describe()
	return {}, {}
end

return ConfigMenu
