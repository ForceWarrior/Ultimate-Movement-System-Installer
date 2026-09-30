--// [Variables]
local ConfigDocs = {}

--// [Do not go past this point]

ConfigDocs.Blocks = {
	Core = {
		Title = "Core",
		Blurb = "Switches for the whole kit",
		Summary = "Switches for the whole kit rather than one move.",
		Notes = {
			"Extras loads the whole MovementMain > Extras folder. Each module in it also has its own Enabled.",
			"UpdatesPerSecond is the main performance dial.",
			"Stamina, breath and fall damage are worked out on the player's side, the server only applies the fall and drowning damage.",
		},
	},
	CameraShake = {
		Title = "Camera Shake",
		Blurb = "The look of every camera shake",
		Summary = "The default look of every camera shake the moves play: how fast it vibrates, how much it rolls and whether it is smooth or a rattle.",
		Notes = {
			"Each move's own CameraShake table only sets the strength and length. The style lives here.",
		},
	},
	StateTransitions = {
		Title = "State Transitions",
		Blurb = "Which moves may follow which",
		Summary = "Which moves may follow which. A move not listed under another cannot start straight out of it.",
		Notes = {
			"Jump in a list means the jump key is allowed out of that move.",
			"Only the pairs you list are checked. Everything else follows the moves' own rules.",
		},
	},
	Stamina = {
		Title = "Stamina",
		Blurb = "The stamina pool and how it refills",
		Summary = "The stamina pool the moves spend from and how it comes back.",
		Notes = {
			"Every move's cost and drain is set in that move's own block.",
			"The bar in StarterGui reads the pool; restyle it freely, keep the Fill frame.",
		},
	},
	Momentum = {
		Title = "Momentum",
		Blurb = "A bonus for keeping speed or chaining moves",
		Summary = "A bonus for keeping up speed or linking moves: run and dash faster, launch further, shorter cooldowns.",
		Notes = {
			"Speed mode rewards not stopping. Chain mode rewards stringing moves together inside the window.",
			"The Affects switches say which moves get the bonus.",
		},
	},
	TouchButtons = {
		Title = "Mobile Buttons",
		Blurb = "On screen buttons for phones and tablets",
		Summary = "The on screen buttons phones and tablets get for the moves: which slot each move uses, where the slots sit, colours and size.",
		Notes = {
			"A move with a KeyCode gets a button by itself. Give it a slot in Actions or it takes the next free one.",
			"Anchor Jump places a slot relative to the jump button, Screen relative to the screen.",
		},
	},
	LocomotionModule = {
		Title = "Core Locomotion",
		Blurb = "Walk, run, jump, swim, climb, land, fall damage",
		Summary = "Walking, running, jumping, air jumps, swimming, drowning, truss climbing, landings, the landing roll and fall damage.",
		Notes = {
			"Never disable this block. Everything else builds on it.",
			"Landings is a list of tiers by fall height, each with its own animation and hold time.",
			"FallDamage.Reductions lets a move soften or cancel the damage while it runs.",
		},
	},
	DashModule = {
		Title = "Dashing",
		Blurb = "A burst of speed on the ground or in the air",
		Summary = "A burst of speed on the ground or in the air, with a speed and animation per direction.",
		Notes = {
			"Ground and Aerial hold the per direction settings. A key set there beats the shared one.",
			"CooldownMode decides whether all dashes share one cooldown, one per ground and air, or one each.",
			"With ChargeEnabled, MovementChargeBar in StarterGui shows the charge. FillFrom and Drains in its BarDriver pick the edge and whether it empties or fills.",
		},
	},
	LeapModule = {
		Title = "Edge Leap",
		Blurb = "A long jump off an edge while running",
		Summary = "A long jump off an edge or a tagged part while running.",
		Notes = {
			"EdgeMode says whether a real edge, a tag, either or anywhere counts.",
		},
	},
	GlideModule = {
		Title = "Glide",
		Blurb = "Glide on a held jump or a key of your own",
		Summary = "Glide forward and sink slowly. StartMode picks how it starts: holding jump in the air, a key that starts it on a press, or a key that glides only while held.",
		Notes = {
			"Gliding into a wall can turn into a wall slide.",
		},
	},
	WallRunModule = {
		Title = "Wall Running",
		Blurb = "Run along a wall and jump off it",
		Summary = "Run along a wall beside you and jump off it.",
		Notes = {
			"SurfaceMode TagOnly limits it to parts tagged WallRunnable.",
			"WrapAroundWalls lets a run follow a wall round a corner.",
		},
	},
	WallClimbModule = {
		Title = "Wall Climbing",
		Blurb = "Climb walls, ceilings and over the top",
		Summary = "Climb walls in any direction, sprint up them, cross ceilings and climb over the top.",
		Notes = {
			"Mode picks how free the climbing is, from any direction down to up and down only.",
			"SurfaceMode TagOnly limits it to parts tagged Climbable.",
		},
	},
	WallJumpModule = {
		Title = "Wall Jumping",
		Blurb = "Grip a wall in the air and jump off it",
		Summary = "Grip a wall in the air and jump off it, away or straight up.",
		Notes = {
			"WallGrip off makes it an instant bounce instead of a hang.",
		},
	},
	VaultingModule = {
		Title = "Vaulting",
		Blurb = "Ledges, hanging, mantling and vaults",
		Summary = "Grab ledges, hang, move along them, mantle low walls and vault over obstacles.",
		Notes = {
			"Variants is a list of vault styles by wall height and speed, each with its own animation.",
			"Mode AutoVault goes straight over instead of grabbing.",
			"MantleTrigger Auto also climbs a ledge your jump will not clear, and a press in the air climbs instead of hanging.",
		},
	},
	MonkeyBarsModule = {
		Title = "Monkey Bars",
		Blurb = "Hang, swing and launch from tagged bars",
		Summary = "Hang from tagged bars, swing harder with a press, launch off and chain bar to bar.",
		Notes = {
			"Bars are parts tagged MonkeyBar. Any shape works.",
		},
	},
	ZiplineModule = {
		Title = "Ziplines & Poles",
		Blurb = "Ride tagged lines and climb tagged poles",
		Summary = "Ride tagged lines downhill and climb tagged poles.",
		Notes = {
			"A line is a part tagged Zipline. An upright one counts as a pole.",
			"Attributes on the part can fix its direction, speed mode and the next line in a chain.",
		},
	},
	RailGrindModule = {
		Title = "Rail Grinding",
		Blurb = "Grind along tagged rails",
		Summary = "Grind along tagged rails, lean, brake, speed up and switch onto crossing rails.",
		Notes = {
			"Rails are parts tagged RailGrind. Pieces close together count as one rail.",
		},
	},
	GrappleModule = {
		Title = "Grappling Hook",
		Blurb = "Fire a rope and swing or pull yourself in",
		Summary = "Fire a rope at a point and swing, pull yourself in, or get dragged to it.",
		Notes = {
			"Tagged parts are preferred targets; TaggedPointsOnly makes them the only ones.",
		},
	},
	ZoneEffectsModule = {
		Title = "Launch Pads & Zones",
		Blurb = "Launch pads, updrafts and wind tunnels",
		Summary = "Tagged parts that throw you, lift you or blow you along: launch pads, updrafts and wind tunnels.",
		Notes = {
			"Tag a part with LaunchPad, Updraft or WindTunnel and it works. The part's size is the zone.",
		},
	},
	CrouchModule = {
		Title = "Crouching",
		Blurb = "Crouch, crawl and charge a bullet jump",
		Summary = "Crouch, crawl under low gaps, and charge a bullet jump by holding the crouch key, then let go or press jump.",
		Notes = {
			"AutoCrouch ducks by itself under a low ceiling.",
			"The bullet jump charge shows on MovementChargeBar in StarterGui, the same bar as the dash charge.",
		},
	},
	ProneModule = {
		Title = "Prone Crawl",
		Blurb = "Lie flat and crawl under low gaps",
		Summary = "Lie flat and crawl, under gaps a crouch cannot pass.",
		Notes = {
			"CrouchWhenBlocked drops you into a crouch when there is no room to go prone.",
		},
	},
	SlideModule = {
		Title = "Sliding",
		Blurb = "Slide along the ground, faster downhill",
		Summary = "Slide along the ground, faster downhill, steerable, with a jump out.",
		Notes = {
			"CarryEntrySpeed makes a running start into a faster slide.",
		},
	},
	DiveModule = {
		Title = "Diving",
		Blurb = "A dive forward, a short hop or a ground pound",
		Summary = "A dive forward in the air, a short hop, or a ground pound straight down.",
		Notes = {
			"Mode picks which of the three it is.",
			"LandingMode Momentum lets you run straight through the landing instead of being planted.",
		},
	},
	CameraModule = {
		Title = "Camera",
		Blurb = "Bob, idle breath, leans, landing dip, first person eye",
		Summary = "How the camera feels: a bob while you move and a slow breath while you stand, leans into turns, a dip on landing, first person eye placement, and a camera style per move.",
		Notes = {
			"Nothing here delays your aim.",
			"LookLeft, LookRight, LookUp and LookDown in a move's layer limit how far you can look while it runs, in degrees from where you face. LookYaw and LookPitch do the same for every move that sets none.",
			"Moves is a layer per move or state. It only needs the keys it changes.",
		},
	},
	Camera2DModule = {
		Title = "2D Camera",
		Blurb = "A fixed side or top down camera",
		Summary = "A fixed side or top down camera for 2D style games.",
		Notes = {
			"Replaces the normal camera feel while on.",
		},
	},
	ShiftLock = {
		Title = "Shift Lock",
		Blurb = "A shift lock of its own, smooth and on your keys",
		Summary = "Replaces the stock shift lock. Your own keys toggle it, the body turns to face the camera at a speed you set, and the camera eases over the shoulder and back instead of snapping.",
		Notes = {
			"The camera feel while locked lives under CameraModule.ShiftLock.",
		},
	},
	BodyLean = {
		Title = "Body Lean",
		Blurb = "The body leans into sideways moves and turns",
		Summary = "The R6 body leans into sideways moves and turns, the angles for every direction sit in Leans.",
		Notes = {
			"IntensityMultiplier scales every angle in Leans at once, 1 uses them as written.",
			"PausedBy lists the moves that straighten the body while they run.",
		},
	},
	HeadMovementModule = {
		Title = "Head Sway",
		Blurb = "The head follows the camera",
		Summary = "The head, and on R15 the body, turn to follow the camera.",
		Notes = {},
	},
	FirstPersonBodyModule = {
		Title = "First Person Body",
		Blurb = "Show the body parts you choose in first person",
		Summary = "Shows your own body in first person, only the parts you pick, so arms and legs are there and nothing sits in front of the eye.",
		Notes = {},
	},
	SpeedEffects = {
		Title = "Speed Effects",
		Blurb = "Wider field of view and trails at speed",
		Summary = "The field of view widens and trails appear on the limbs as you speed up.",
		Notes = {
			"ActiveDuring says when the effects may show, AlwaysDuring which moves always get them.",
			"TrailLimbs lists which limbs carry a trail for each rig, with how far sideways it sits and how wide it is.",
		},
	},
	FootstepsModule = {
		Title = "Footsteps",
		Blurb = "Footstep sounds and dust per material",
		Summary = "Footstep sounds and dust per ground material.",
		Notes = {
			"Sounds and particles are found by material name in the folders you point at.",
		},
	},
	WindController = {
		Title = "Wind",
		Blurb = "Wind streaks at speed, tagged parts sway",
		Summary = "Wind streaks past the camera when you move fast. Any part you tag WindShake sways with the same wind, trees, grass, flags, whatever you tag.",
		Notes = {
			"A tagged part can carry WindPower, WindSpeed and WindDirection attributes to override the block for itself.",
		},
	},
	MovementTemplate = {
		Title = "Custom Move Template",
		Blurb = "An example move that shows how to make your own",
		Summary = "A finished example move, a short forward surge, to copy when you write a move of your own.",
		Notes = {
			"Every key it reads is in this block. A custom move has no defaults inside it, no block means no move.",
			"The module, the block and the module's Name must all match.",
		},
	},
}

function ConfigDocs.For(Name)
	return ConfigDocs.Blocks[Name]
end

function ConfigDocs.Title(Name)
	local Entry = ConfigDocs.Blocks[Name]
	if Entry and Entry.Title then
		return Entry.Title
	end
	local Pretty = Name:gsub("Module$", "")
	Pretty = Pretty:gsub("(%l)(%u)", "%1 %2")
	return Pretty
end

return ConfigDocs
