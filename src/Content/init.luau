--// [Variables]
local Content = {}

--// [Do not go past this point]

Content.WindowTitle = "Ultimate Movement System Installer"
Content.ToolbarName = "Ultimate Movement System"
Content.ButtonLabel = "UMS Installer"
Content.ButtonTooltip = "Open the Ultimate Movement System installer"
Content.TabOrder = { "About", "Install", "Presets", "Config", "API", "Library" }

Content.About = require(script.About)
Content.Animations = require(script.Animations)
Content.Config = require(script.Config)
Content.Gate = require(script.Gate)
Content.Install = require(script.Install)
Content.Landing = require(script.Landing)
Content.Presets = require(script.Presets)
Content.Requirements = require(script.Requirements)
Content.Api = require(script.Api)
Content.Library = require(script.Library)

return Content
