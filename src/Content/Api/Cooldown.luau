return {
	Name = "Cooldown",
	Title = "Cooldowns",
	Blurb = "One timer per module, kept for you",
	Summary = "The manager keeps a cooldown per module name, so it survives your move stopping and "
		.. "starting and you never have to track a timestamp yourself.",
	Rows = {
		{ Key = "Api.StartCooldown(Duration, Label)", Value = "no return",
			Summary = "Starts it, in seconds. Usually the last line of Enter. The optional Label is a "
				.. "word for the on screen cooldown indicator (StarterGui > CooldownIndicator) to look up in "
				.. "its Messages table, for a move that shares one timer between several forms the way the "
				.. "dash does; without it the indicator names the module.",
			Code = "function MyMove:Enter()\n\tApi.StartCooldown(Api.Config.Cooldown)\nend" },
		{ Key = "Api.OnCooldown()", Value = "-> boolean",
			Summary = "Is it still running. Usually the first line of CanEnter.",
			Code = "function MyMove:CanEnter()\n\tif Api.OnCooldown() then\n\t\treturn Api.Refuse(\"on cooldown\")\n\tend\n\treturn true\nend" },
	},
}
