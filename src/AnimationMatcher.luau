--// [Modules]
local Settings = require(script.Parent.Settings)

--// [Variables]
local AnimationMatcher = {}
local ModelOwners = {
	WallRun = { "WallRunModule" },
	WallClimb = { "WallClimbModule" },
	WallJump = { "WallJumpModule" },
	Grapple = { "GrappleModule" },
	Leap = { "LeapModule" },
	Glide = { "GlideModule" },
	Crouch = { "CrouchModule" },
	Prone = { "ProneModule" },
	Vaulting = { "VaultingModule" },
	Dash = { "DashModule" },
	Dive = { "DiveModule" },
	MonkeyBar = { "MonkeyBarsModule" },
	Slide = { "SlideModule" },
	Ziplining = { "ZiplineModule" },
	RailGrinding = { "RailGrindModule" },
	Core = { "LocomotionModule", "LandingRollModule" },
}
local Stem = { arial = "aerial", front = "forward", back = "backward" }
local Stop = { ground = true, animation = true, animations = true }
local Overrides = {
	LocomotionModule = {
		Death = { R6 = "DiedFall", R15 = "DiedFall" },
		DeathIdle = { R6 = "DiedLoop", R15 = "DiedLoop" },
	},
	ZiplineModule = {
		Ride = { R6 = "Ziplining", R15 = "Ziplining" },
		SteepRide = { R6 = "SteepZipline", R15 = "SteepZipline" },
		PoleUp = { R6 = "PoleZipliningUpward", R15 = "ZipliningUpward" },
		PoleDown = { R6 = "PoleZipliningDown", R15 = "ZipliningDownward" },
	},
	RailGrindModule = {
		RailGrind = { R6 = "RailGrind", R15 = "RailgrindingForward" },
		FastGrind = { R6 = "FastRailGrind", R15 = "RailgrindingFast" },
		LeanLeft = { R6 = "RailGrindLeft", R15 = "RailGrindLeft" },
		LeanRight = { R6 = "RailGrindRight", R15 = "RailgrindRight" },
	},
	DiveModule = {
		AirDiveLand = { R6 = "AirDiveLand", R15 = "DiveLanding" },
		GroundPoundLand = { R6 = "GroundPoundLand", R15 = "GroundPoundLanding" },
	},
	WallClimbModule = {
		SprintClimb = { R6 = "WallClimbRun", R15 = "ClimbRun" },
		Climb = { R6 = "Climb", R15 = "Climbing" },
		ClimbUp = { R6 = "Climb", R15 = "Climbing" },
		ClimbDown = { R6 = "DownClimb", R15 = "ClimbDown" },
		ClimbIdle = { R6 = "ClimbIdle", R15 = "ClimbingIdle" },
	},
	VaultingModule = {
		LedgeClimb = { R6 = "Vault", R15 = "Vault" },
	},
	WallJumpModule = {
		JumpOff = { R6 = "WallJump", R15 = "WallJump" },
		JumpOffLeft = { R6 = "LeftWallJump", R15 = "WallJumpLeft" },
		JumpOffRight = { R6 = "RightWallJump", R15 = "WallJumpRight" },
	},
	WallRunModule = {
		WallRunLeft = { R6 = "WallRunLeft", R15 = "LeftWallRun" },
		WallRunRight = { R6 = "WallRunRight", R15 = "RightWallRun" },
		JumpOffLeft = { R6 = "WalkRunJumpOffLeft", R15 = "JumpOffLeft" },
		JumpOffRight = { R6 = "WallRunJumpOffRight", R15 = "JumpOffRight" },
	},
}

--// [Do not go past this point]

local function Tokens(Text)
	local Spaced = Text:gsub("(%l)(%u)", "%1 %2"):gsub("(%u)(%u%l)", "%1 %2")
	local Seen, Out = {}, {}
	for Word in Spaced:gmatch("%a+") do

		local Low = Word:lower():gsub("s$", ""):gsub("ing$", ""):gsub("e$", "")
		Low = Low:gsub("(%a)%1", "%1")
		Low = Stem[Low] or Low
		if Low ~= "" and not Stop[Low] and not Seen[Low] then
			Seen[Low] = true
			table.insert(Out, Low)
		end
	end
	table.sort(Out)
	return table.concat(Out, "|")
end

function AnimationMatcher.FindSource()
	local Direct = workspace:FindFirstChild(Settings.AnimationSourceName)
	if Direct then
		return Direct
	end
	for _, Child in workspace:GetChildren() do
		local Nested = Child:FindFirstChild(Settings.AnimationSourceName, true)
		if Nested then
			return Nested
		end
	end
	return nil
end

function AnimationMatcher.Clips()
	local Root = AnimationMatcher.FindSource()
	local Clips = {}
	if not Root then
		return Clips
	end
	for _, Rig in Root:GetChildren() do
		for _, Model in Rig:GetChildren() do
			local Saves = Model:FindFirstChild("AnimSaves")
			if Saves then
				local Owners = {}
				for Word, List in ModelOwners do
					if Model.Name:find(Word, 1, true) then
						for _, Name in List do
							Owners[Name] = true
						end
					end
				end
				for _, Clip in Saves:GetChildren() do
					if Clip:IsA("KeyframeSequence") then
						table.insert(Clips, {
							Rig = Rig.Name,
							Name = Clip.Name,
							Model = Model.Name,
							Owners = Owners,
							Instance = Clip,
						})
					end
				end
			end
		end
	end
	return Clips
end

function AnimationMatcher.Describe(Row)
	local Rig = Row.Key:match("^(R1?[56])")
	for Piece in Row.Path:gmatch("[^%.]+") do
		if Piece == "R6" or Piece == "R15" then Rig = Piece end
	end
	if Rig ~= "R6" and Rig ~= "R15" then
		Rig = nil
	end
	local Base = Row.Key:gsub("^R1?[56]", ""):gsub("AnimationId$", "")
	local Context = {}
	for Piece in Row.Path:gmatch("[^%.]+") do
		if Piece ~= Row.Module and Piece ~= Row.Key and Piece ~= "R6" and Piece ~= "R15"
			and not Piece:match("^%[%d+%]$") then
			table.insert(Context, Piece)
		end
	end
	return Rig, Base, Context
end

local VariantClips = {
	Mantle = { R6 = "Mantling", R15 = "Mantle" },
	TrussVault = { R6 = "Vault", R15 = "Vault" },
	SideMantleRight = { R6 = "RightMantle", R15 = "RightMantle" },
	SideMantleLeft = { R6 = "LeftMantle", R15 = "LeftMantle" },
}

local function VariantPick(Row, Rig)
	local Name = Row.Text and Row.Text:match('Name%s*=%s*"([%w_]+)"')
	if not Name or not Rig then
		return nil
	end
	local Side = Row.Text:match('Side%s*=%s*"([%w_]+)"')
	local Variant = VariantClips[Name] or VariantClips[Name .. (Side or "")]
	return Variant and Variant[Rig]
end

local function TrailingNumber(Text)
	return tonumber(Text:match("(%d+)%s*$")) or 0
end

local function ListLength(Raw)
	if Raw:sub(1, 1) ~= "{" then
		return 1
	end
	local Count = 0
	for _ in Raw:gmatch("%d+") do
		Count += 1
	end
	return math.max(Count, 1)
end

function AnimationMatcher.Match(Rows, Clips, Manual)
	local ByRig = {}
	for _, Clip in Clips do
		ByRig[Clip.Rig] = ByRig[Clip.Rig] or {}
		ByRig[Clip.Rig][Clip.Name] = Clip
	end

	local Result = {}
	for _, Row in Rows do
		local Rig, Base, Context = AnimationMatcher.Describe(Row)
		local Entry = { Row = Row, Rig = Rig, Base = Base, Candidates = {}, Choices = {} }
		for _, Clip in Clips do
			if Clip.Rig == Rig and Clip.Owners[Row.Module] then table.insert(Entry.Choices, Clip) end
		end
		if #Entry.Choices == 0 then
			for _, Clip in Clips do
				if Clip.Rig == Rig then table.insert(Entry.Choices, Clip) end
			end
		end
		table.sort(Entry.Choices, function(Left, Right) return Left.Name < Right.Name end)

		local Chosen = Manual and Manual[Row.Path]
		local Picked = VariantPick(Row, Rig)
		local Override = Overrides[Row.Module] and Overrides[Row.Module][Base]
		local Named = Override and Rig and Override[Rig]

		if Chosen and Rig and ByRig[Rig] and ByRig[Rig][Chosen] then
			Entry.Clip = ByRig[Rig][Chosen]
			Entry.How = "manual"
		elseif Picked and ByRig[Rig] and ByRig[Rig][Picked] then
			Entry.Clip = ByRig[Rig][Picked]
			Entry.How = "variant"
		elseif Named and ByRig[Rig] and ByRig[Rig][Named] then
			Entry.Clip = ByRig[Rig][Named]
			Entry.How = "named"
		else
			local Wanted = Tokens(Base .. " " .. table.concat(Context, " "))
			Entry.Wanted = Wanted
			local WithModule = Tokens(Base .. " " .. table.concat(Context, " ")
				.. " " .. Row.Module:gsub("Module$", ""))
			for _, Clip in Clips do
				if Clip.Rig == Rig and Clip.Owners[Row.Module] then
					local Key = Tokens(Clip.Name)
					if Key == Wanted or Key == WithModule then
						table.insert(Entry.Candidates, Clip)
					end
				end
			end
			if #Entry.Candidates == 1 then
				Entry.Clip = Entry.Candidates[1]
				Entry.How = "name"
			elseif #Entry.Candidates > 1 then
				Entry.How = "ambiguous"
			else
				Entry.How = "none"
				for _, Clip in Clips do
					if Clip.Rig == Rig and Clip.Owners[Row.Module] then
						table.insert(Entry.Candidates, Clip)
					end
				end
			end
		end
		Entry.Slots = ListLength(Row.Raw)
		Result[Row.Path] = Entry
	end

	local Groups = {}
	for _, Row in Rows do
		local Entry = Result[Row.Path]
		if Entry.How == "ambiguous" then
			local Key = Row.Module .. "|" .. tostring(Entry.Rig) .. "|" .. tostring(Entry.Wanted)
			Groups[Key] = Groups[Key] or { Entries = {}, Pool = {} }
			table.insert(Groups[Key].Entries, Entry)
			for _, Clip in Entry.Candidates do
				Groups[Key].Pool[Clip.Name] = Clip
			end
		end
	end

	for _, Group in Groups do
		local Pool = {}
		for _, Clip in Group.Pool do
			table.insert(Pool, Clip)
		end
		table.sort(Pool, function(Left, Right)
			local A, B = TrailingNumber(Left.Name), TrailingNumber(Right.Name)
			if A ~= B then
				return A < B
			end
			return Left.Name < Right.Name
		end)
		table.sort(Group.Entries, function(Left, Right)
			return Left.Row.ValueStart < Right.Row.ValueStart
		end)

		local Cursor = 0
		for _, Entry in Group.Entries do
			local Take = {}
			for _ = 1, Entry.Slots do
				if #Pool > 0 then
					table.insert(Take, Pool[Cursor % #Pool + 1])
					Cursor += 1
				end
			end
			if #Take == Entry.Slots then
				Entry.Clip = Take[1]
				Entry.Clips = Take
				Entry.How = "ordered"
			end
		end
	end

	return Result
end

return AnimationMatcher
