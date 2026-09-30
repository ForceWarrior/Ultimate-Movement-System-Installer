return {
	Name = "EmoteSupport",
	Title = "Emote system support",
	Blurb = "Emotes and moves that agree on who has the body",
	Summary = "Made for the Ultimate Emote System by Force Warrior and Cookie. One custom move that follows the "
		.. "emote: while a stand still emote plays no move can start, and a real move during a free emote ends it. "
		.. "Another emote system has to write the EmoteId and EmoteMovement attributes on the character itself, and EmoteSpeed if the emote sets a walk speed.",
	Notes = {
		"The module needs no key. It watches the EmoteId and EmoteMovement attributes the emote system writes on your character from V1.1 on, and EmoteSpeed from V1.2 on.",
		"A stand still or walking emote cannot hold the body while swimming or on a truss, so the module ends it, unless Core.AllowedInWater or Core.AllowedWhileClimbing names EmoteSupport. A free emote never holds the body, so those lists leave it alone.",
	},

	Groups = {
		{
			Title = "What goes where",
			Rows = {
				{ Key = "EmoteSupport", Value = "ReplicatedStorage > Modules > Movement > MovementMain > Custom",
					Summary = "The custom move. Loads at the next spawn." },
				{ Key = "Red", Value = "a Workspace folder, then ReplicatedStorage > Modules > Util",
					Summary = "Only when Red is in the place twice. A one line redirect to the kit's copy that waits in the folder until you put it in place of the emote system's copy." },
				{ Key = "Config.EmoteSupport", Value = "MovementConfig",
					Summary = "Added when MovementConfig has no block of that name. A block already there keeps its values and only gets the keys it lacks." },
			},
		},
		{
			Title = "How it behaves",
			Rows = {
				{ Key = "A stand still emote", Value = "holds the body",
					Summary = "No move can start and the speed is the emote's." },
				{ Key = "A walking emote", Value = "walks",
					Summary = "You keep control, at the emote's own speed." },
				{ Key = "A move during a free emote", Value = "ends the emote",
					Summary = "That is StopEmoteOnMove. IgnoredMoves lists the moves that may run without ending it." },
			},
		},
		{
			Title = "If something is off",
			Rows = {
				{ Key = "Emotes still get interrupted", Value = "module not loaded",
					Summary = "It has to sit in MovementMain > Custom and be named EmoteSupport. The Output at spawn names what failed." },
				{ Key = "The emote never holds", Value = "no attributes",
					Summary = "Select your character while an emote plays and look for EmoteId in its attributes. If it is missing your emote system is older than V1.1, update it." },
			},
		},
	},

	Settings = {
		Enabled = { Summary = "Emotes and moves stop fighting over the body.", Accepts = "true or false" },
		IgnoredMoves = { Summary = "Moves that may start without ending the emote.", Accepts = "a list of module names" },
		StopEmoteOnMove = { Summary = "Starting a move ends the emote.", Accepts = "true or false" },
	},
}
