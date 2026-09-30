return {
	Name = "ConfigMenu",
	Title = "Config menu",
	Blurb = "Change any config value while you play",
	Summary = "A window you open while playing that lists every block and key of MovementConfig and lets you change them on the spot. "
		.. "Search finds any setting by name, value or description, and the strip under the list says what the setting does and what it takes. "
		.. "Changes last for the play session, Export writes them as lines you paste into MovementConfig to keep them.",

	Notes = {
		"The MovementConfigMenu window in StarterGui and the row templates under the module are plain instances laid out in scale, so they fit any screen. Restyle them, keep the names.",
		"Remove deletes the module with its templates and the MovementConfigMenu window, so copy a restyle out first.",
		"With StudioOnly on, a published game never builds the window.",
		"Docs under the module holds the descriptions the strip and search use. It is about 180 KB and ships to every player of a published game, delete it to save that, the menu works without it.",
	},

	Groups = {
		{
			Title = "What goes where",
			Rows = {
				{ Key = "ConfigMenu", Value = "ReplicatedStorage > Modules > Movement > MovementMain > Custom",
					Summary = "The module, with a Templates folder of the rows it shows and the Docs module under it. Loads at the next spawn like any custom move." },
				{ Key = "MovementConfigMenu", Value = "StarterGui",
					Summary = "The window, a ScreenGui you can see and restyle in the Explorer. Your first spawn copies it into PlayerGui like any StarterGui item." },
				{ Key = "Config.ConfigMenu", Value = "MovementConfig",
					Summary = "Added when MovementConfig has no block of that name. A block already there keeps its values and only gets the keys it lacks." },
			},
		},
		{
			Title = "Using it",
			Rows = {
				{ Key = "Opening it", Value = "OpenKey or OpenButton",
					Summary = "Either one opens and closes the window. On a phone or tablet a CONFIG button sits with the move buttons." },
				{ Key = "Finding a setting", Value = "Search",
					Summary = "Type part of a name, a value such as a sound name, or a word from its description. The results are the real controls, Enter or a result's heading opens its table." },
				{ Key = "Knowing a setting", Value = "the strip under the list",
					Summary = "Point at or click a row to see its full path, the range it takes, what it was before you changed it and what it does. A value outside the range is clamped and the strip says so." },
				{ Key = "Numbers", Value = "field, minus and plus",
					Summary = "Type and press Enter, or step it. Hold minus or plus to keep stepping, right click them for ten steps at once." },
				{ Key = "Keys", Value = "press the new one",
					Summary = "Click the key, press the one you want, click it again to keep the old one. The strip warns when another setting already uses that key." },
				{ Key = "Tables", Value = "step into them",
					Summary = "Open shows the keys inside, Back goes up a level." },
				{ Key = "Lists", Value = "+ Add and x",
					Summary = "Add puts a copy of the last entry at the end, or asks which move where the kit wants a name, x takes one out." },
				{ Key = "Choices", Value = "pick from a list",
					Summary = "Modes, move and state names and enum values drop down, so no name has to be guessed." },
				{ Key = "Undoing", Value = "Revert and Changes",
					Summary = "Revert in the strip puts one setting back. Changes lists everything you changed with what it was, Revert all asks once more before putting it all back." },
				{ Key = "Keeping changes", Value = "Changes, then Export",
					Summary = "Export writes one line per change, selected so Ctrl+C copies them, and prints them to Output too. Paste them above return Config in MovementConfig." },
				{ Key = "Problems", Value = "Validate",
					Summary = "Lists every problem with the setting's row right under it, so you fix it where it is reported. Fixed problems drop out as you type." },
				{ Key = "Reload", Value = "restarts the kit",
					Summary = "For the keys a move reads once at spawn. It turns orange when you changed something since the last one, and the menu reopens where you left it." },
				{ Key = "From a script", Value = "Manager.States.ConfigMenu:Toggle()",
					Summary = "The module sits on the manager like a move.",
					Code = "local MovementMain = require(game.ReplicatedStorage.Modules.Movement.MovementMain)\nlocal Menu = MovementMain.GetManager().States.ConfigMenu\nif Menu then Menu:Toggle() end" },
			},
		},
	},

	Settings = {
		Enabled = { Summary = "Loads the in game config menu.", Accepts = "true or false" },
		OpenButton = { Summary = "The controller button that opens the menu.", Accepts = "an Enum.KeyCode" },
		OpenKey = { Summary = "The key that opens the menu.", Accepts = "an Enum.KeyCode" },
		Scale = { Summary = "Makes the window bigger or smaller.", Accepts = "a multiplier, 1 is normal size" },
		StudioOnly = { Summary = "The menu only exists in Studio play sessions.", Accepts = "true or false" },
	},
}
