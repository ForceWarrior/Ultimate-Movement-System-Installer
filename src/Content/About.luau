return {
	{
		Heading = "Built with AI assistance",
		Body = "This installer was built with AI assistance and tested by hand.",
	},
	{
		Heading = "How the install works",
		Body = "Put the package in Workspace. Every model in it is named UNGROUP IN <destination> and its contents go there. "
			.. "Anything of yours with the same name is kept unless you tick Replace mine. The whole install is one undo step.",
	},
	{
		Heading = "Animations",
		Body = "The Install tab lists every animation id in your config and matches it to a clip in the package. "
			.. "Tick what you want, pick where to publish, press Upload. Clips go through AssetService, no login involved. "
			.. "Each clip uploads once and the new ids are written into the config. Slots that already hold an id are shown for approval first.",
	},
	{
		Heading = "Presets",
		Body = "A preset is your whole MovementConfig saved under a name. It lives with the plugin, so it follows you between places. "
			.. "Share one as a code: it holds only what differs from the shipped defaults, so most fit in a chat message. "
			.. "Pasting it applies those values and touches nothing else. Animation ids stay out unless you tick them in.",
	},
	{
		Heading = "Config",
		Body = "Every block and every setting, what it does, what it accepts and the comment next to it in the file. It reads the live config.",
	},
	{
		Heading = "API",
		Body = "How to write your own move: one ModuleScript in MovementMain > Custom and the Api the kit hands it. "
			.. "Every function and field, and a worked example you can copy.",
	},
}
