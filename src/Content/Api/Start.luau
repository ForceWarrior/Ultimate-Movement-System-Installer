return {
	Name = "Start",
	Title = "Getting started",
	Blurb = "Where a custom move lives and how it gets loaded",
	Summary = "A custom move is one ModuleScript in MovementMain > Custom. Copy MovementTemplate, rename it, keep Name = script.Name. Custom modules load after the shipped ones, so they can never replace one.",
	Notes = {
		"The table's Name must equal the script's name. The loader matches them and skips a module whose names disagree.",
		"RequiresApi is the contract version you wrote against. This build is Api version 1 and accepts 1 and up, so put 1.",
		"Nothing in Custom is touched when the kit updates.",
	},
	Rows = {
		{ Key = "The smallest move that works", Value = "start here",
			Summary = "A few lines, a key and a config block. Copy this into a new ModuleScript in Custom named SuperJump and add the block to MovementConfig. No block, no move.",
			Code = "local SuperJump = {}\n\nSuperJump.Name = script.Name\nSuperJump.RequiresApi = 1\n\nlocal Api = nil\n\nfunction SuperJump:Init(NewApi)\n\tApi = NewApi\n\tApi.BindKey(function(_, InputState)\n\t\tif InputState == \"Begin\" and Api.OnGround() then\n\t\t\tApi.RootPart.AssemblyLinearVelocity += Vector3.new(0, Api.Config.Power, 0)\n\t\tend\n\tend)\nend\n\nreturn SuperJump\n\n-- and in MovementConfig, after the shipped blocks\nConfig.SuperJump = { Enabled = true, KeyCode = Enum.KeyCode.H, ConsoleInput = Enum.KeyCode.DPadRight, Power = 90 }" },
		{ Key = "Where it goes", Value = "MovementMain > Custom",
			Summary = "One ModuleScript per move. If part of it grows big enough to want its own file, that file becomes a CHILD of your module, never a sibling somewhere else.",
			Note = "MovementMain.LoadModules(Custom) runs after LoadModules(Core).",
			Code = "ReplicatedStorage\n  Modules\n    Movement\n      MovementMain\n        Core          <- the shipped moves, leave these alone\n        Custom        <- yours goes here\n          MovementTemplate\n          SuperJump   <- your new ModuleScript" },
		{ Key = "The type", Value = "MovementTypes.Api<Block>",
			Summary = "Requiring MovementTypes gives your editor autocomplete on the Api. Every shipped block has a type named after it, read straight off MovementConfig, and Api<Block> makes Api.Config autocomplete too. For a block of your own, typeof(MovementConfig.MyMove) is its type.",
			Code = "local MovementTypes = require(script:FindFirstAncestor(\"Movement\").MovementTypes)\n\nlocal Api: MovementTypes.Api<MovementTypes.MovementTemplateConfig> = nil\n\nfunction SuperJump:Init(NewApi: MovementTypes.Api<MovementTypes.MovementTemplateConfig>)\n\tApi = NewApi\n\t-- type Api. now and your editor lists every function the Api has, Api.Config. lists every key of the block\nend" },
	},
}
