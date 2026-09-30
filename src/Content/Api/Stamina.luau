return {
	Name = "Stamina",
	Title = "Stamina",
	Blurb = "Spending and draining, when the game has it turned on",
	Summary = "Stamina is a feature that can be turned off entirely. Ask StaminaEnabled first, or "
		.. "a move that costs stamina becomes impossible in a game that does not use it.",
	Rows = {
		{ Key = "Api.StaminaEnabled()", Value = "-> boolean",
			Summary = "Is stamina on in this game at all. Check this before gating anything on it.",
			Code = "function MyMove:CanEnter()\n\tif Api.StaminaEnabled() and Api.Stamina() < Api.Config.Cost then\n\t\treturn Api.Refuse(\"not enough stamina\")\n\tend\n\treturn true\nend" },
		{ Key = "Api.Stamina()", Value = "-> number",
			Summary = "How much is left right now.",
			Code = "local Left = Api.Stamina()\nApi.Log.Debug(\"stamina left\", Left)" },
		{ Key = "Api.SpendStamina(Amount)", Value = "-> boolean",
			Summary = "Takes a lump sum. Returns false and takes nothing when there is not enough, so it is safe to use as the test itself.",
			Code = "function MyMove:Enter()\n\tApi.SpendStamina(Api.Config.Cost)\nend\n\n-- or as the test, when you have no CanEnter\nif not Api.SpendStamina(10) then\n\treturn -- nothing was taken\nend" },
		{ Key = "Api.DrainStamina(PerSecond, DeltaTime)", Value = "-> boolean",
			Summary = "Takes a rate over one tick, for a move that costs while it is held. Returns false once it has run out, which is your cue to stop.",
			Code = "function MyMove:Update(DeltaTime)\n\tif not Api.DrainStamina(Api.Config.DrainPerSecond, DeltaTime) then\n\t\tApi.Stop()\n\t\treturn\n\tend\nend" },
	},
}
