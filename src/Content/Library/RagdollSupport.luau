return {
	Name = "RagdollSupport",
	Title = "Ragdoll support",
	Blurb = "The kit holds still while a ragdoll has the body",
	Summary = "Made for the ragdoll system by Force Warrior and Cookie, and built into the kit, so there is nothing to insert. While the character carries a MovementHold attribute the kit stops the running move "
		.. "and refuses every move until it clears. With no move running, PlatformStand or the Physics humanoid state holds it the same way, "
		.. "so a ragdoll built on either needs no code at all.",
	Notes = {
		"A ragdoll that can start in the middle of a move should set MovementHold, PlatformStand and Physics only count once no move is running.",
		"The same attribute holds the kit for a cutscene, a stun or a knockback. true or any name works.",
		"The API tab's Outside hooks page has the same hold from client code.",
	},

	Groups = {
		{
			Title = "From your own code",
			Rows = {
				{ Key = "The attribute", Value = "MovementHold, on the character",
					Summary = "Set it when the ragdoll starts, clear it when it ends. The server or the player's own client can set it.",
					Code = "-- when the ragdoll starts\nCharacter:SetAttribute(\"MovementHold\", \"Ragdoll\")\n\n-- when it ends\nCharacter:SetAttribute(\"MovementHold\", nil)" },
			},
		},
		{
			Title = "Settings that meet a ragdoll",
			Rows = {
				{ Key = "Core.SuppressTripStates", Value = "no Ragdoll state",
					Summary = "While it is on, the humanoid can never enter the Ragdoll or FallingDown state. The Ragdoll state is no hold either way, so use Physics or PlatformStand, or set MovementHold." },
				{ Key = "Core.DisableCollisionOnDeath", Value = "limbs on death",
					Summary = "While it is on, every part but the root and the torso stops colliding on death, so the limbs of a death ragdoll sink through the floor. Switch it off if your ragdoll runs on death." },
			},
		},
		{
			Title = "If something is off",
			Rows = {
				{ Key = "Moves still start while ragdolled", Value = "no signal",
					Summary = "Your ragdoll sets neither MovementHold nor PlatformStand nor the Physics state. Set the attribute, two lines." },
			},
		},
	},
}
