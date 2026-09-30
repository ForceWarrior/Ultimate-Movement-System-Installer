--// [Modules]
local ConfigScanner = require(script.Parent.Parent.Parent.ConfigScanner)

--// [Variables]
local States = { "Idle", "Walking", "Running", "Swimming", "Climbing", "Airborne" }

--// [Do not go past this point]

local function MovesInPlace()
	local Config = ConfigScanner.Module()
	local Main = Config and Config.Parent and Config.Parent:FindFirstChild("MovementMain")
	if not Main then
		return nil
	end
	local Found = {}
	for _, FolderName in { "Core", "Extras", "Custom" } do
		local Folder = Main:FindFirstChild(FolderName)
		local Names = {}
		if Folder then
			for _, Child in Folder:GetChildren() do
				if Child:IsA("ModuleScript") then
					table.insert(Names, Child.Name)
				end
			end
		end
		table.sort(Names)
		Found[FolderName] = Names
	end
	return Found
end

local function MovesRow()
	local Found = MovesInPlace()
	if not Found then
		return { Key = "The moves in this place", Value = "kit not installed",
			Summary = "Install the kit and open this page again: every module under MovementMain > Core, Extras and Custom is listed here by name." }
	end
	local Lines = {}
	for _, FolderName in { "Core", "Extras", "Custom" } do
		table.insert(Lines, "-- " .. FolderName .. "\n" .. (#Found[FolderName] > 0 and table.concat(Found[FolderName], "\n") or "(none)"))
	end
	return { Key = "The moves in this place", Value = (#Found.Core + #Found.Extras + #Found.Custom) .. " names, read off the place when this window opened",
		Summary = "Every ModuleScript under MovementMain > Core, Extras and Custom. A custom move you add appears here next time the plugin opens.",
		Code = table.concat(Lines, "\n\n") }
end

local Page = {
	Name = "Names",
	Title = "Names the kit understands",
	Blurb = "One vocabulary for every list that names a move or a state",
	Summary = "Wherever MovementConfig asks for a move or a state the same words apply: a module name, or one of six words for what the body is doing. Anything else is warned about in the Output at spawn.",
	Notes = {
		"One name per entry, each in its own quotes. { \"WallJumpModule, Swimming\" } is one string and matches nothing.",
		"Api.ActiveMove() returns a move by the same name, and Api.OnMoveStarted hands your callback the same name, so a custom move can compare against them directly.",
		"Running means sprinting. Airborne means off the ground and not swimming or climbing. Idle and Walking are on the ground with no move running.",
	},
}

local Static = {
	{ Key = "A move", Value = "its module name",
		Summary = "DashModule, SlideModule, WallJumpModule, MovementTemplate, your own custom move: the name of the ModuleScript is the word, exactly as spelled.",
		Code = "BlockedDuring = { \"SlideModule\" }\nAlwaysDuring = { \"WallJumpModule\" }\nChainMoves = { \"DashModule\", \"SlideModule\" }" },
	{ Key = "What the body is doing", Value = table.concat(States, ", "),
		Summary = "Six states read off the humanoid. Running is sprinting, Airborne is off the ground and not in water or on a truss.",
		Code = "AlwaysDuring = { \"Swimming\", \"Airborne\" }\nBlockedDuring = { \"Swimming\" }" },
	{ Key = "Everything", Value = "always true",
		Summary = "Matches whatever the body is doing. ActiveDuring = { \"Everything\" } is the kit's own default for the speed effects.",
		Code = "ActiveDuring = { \"Everything\" }" },
	{ Key = "Default", Value = "CameraModule.Moves only",
		Summary = "The camera's base layer, the settings every other entry in Moves sits on top of. It is not a state and means nothing in the other lists.",
		Code = "Moves = {\n\tDefault = { Offset = Vector3.new(0, 0, 0) },\n\tRunning = { Smoothing = { BankDegrees = 4.5 } },\n\tSlideModule = { Offset = Vector3.new(0, -0.8, -0.5) },\n}" },
	{ Key = "Jump, Ground, All", Value = "StateTransitions.Map only",
		Summary = "StateTransitions says what may follow what. Its targets are move names plus Jump for the jump key, Ground for being back on the ground, and All for anything.",
		Code = "StateTransitions = {\n\tMap = {\n\t\tProneModule = { \"CrouchModule\", \"Jump\" },\n\t\tCrouchModule = { \"ProneModule\", \"Jump\" },\n\t},\n}" },
	{ Key = "A sub layer", Value = "CameraModule.Moves only",
		Summary = "A move that has camera layers of its own is addressed as the move name, a dot, and the layer, in brackets because of the dot.",
		Code = "[\"WallClimbModule.Sprint\"] = { Offset = Vector3.new(0, 1, 1) }" },
	{ Key = "In water and on a truss", Value = "Core.AllowedInWater, Core.AllowedWhileClimbing",
		Summary = "A move not named in these two lists is refused while swimming or climbing a truss. A custom move is safe by default; one name opts it in.",
		Code = "AllowedInWater = { \"MovementTemplate\" }\nAllowedWhileClimbing = { \"MovementTemplate\" }" },
	{ Key = "Where the names are used", Value = "every list that names a move",
		Summary = "AllowedInWater and AllowedWhileClimbing on Core, BlockedDuring on a move, ActiveDuring and AlwaysDuring on SpeedEffects, BobMoves and Moves on the camera, FallDamage.Reductions, StateTransitions.Map, PausedBy, MovePlaybackSpeeds and ChainMoves.",
		Code = "-- from a custom move\nfor _, Name in Api.Config.ChainMoves do\n\tif Api.ActiveMove() == Name then\n\t\treturn true\n\tend\nend" },
	{ Key = "What the check says", Value = "at spawn, in the Output",
		Summary = "A name the kit does not know, or two names in one string, is warned about with the entry it sits in. Nothing is switched off, that entry just never matches.",
		Code = "[ConfigValidator] SpeedEffects.AlwaysDuring[1]: \"WallJumpModule, Swimming\" is several names in one string, use { \"WallJumpModule\", \"Swimming\" }" },
}

return setmetatable(Page, {
	__index = function(_, Key)
		if Key == "Rows" then
			local Rows = table.clone(Static)
			table.insert(Rows, MovesRow())
			return Rows
		end
		return nil
	end,
})
