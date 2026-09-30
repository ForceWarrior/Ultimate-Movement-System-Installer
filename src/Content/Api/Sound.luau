return {
	Name = "Sound",
	Title = "Sounds",
	Blurb = "Playing a sound other players can hear",
	Summary = "Sounds go through the kit's asset layer so the server relay can forward them to the "
		.. "other players. Playing a Sound instance yourself is heard by nobody else.",
	Rows = {
		{ Key = "Api.Sound(Value, FallbackName)", Value = "-> Sound?",
			Summary = "Turns a config value into a Sound. The kit's own slots name their Sound under Movement > SFX > MovementSFX, give yours a folder in Custom the same way. A plain sound id works too, and a Sound with no id plays nothing.",
			Code = "-- with Config.MyMove = { WhooshSoundId = \"ReplicatedStorage.Modules.Movement.SFX.MovementSFX.Custom.MyMove.Whoosh\" }\n-- or an id: WhooshSoundId = \"rbxassetid://1234567890\"\nlocal Whoosh = Api.Sound(Api.Config.WhooshSoundId, \"Whoosh\")" },
		{ Key = "Api.PlaySound(Sound)", Value = "no return",
			Summary = "Plays it and tells the replicator, so other clients hear it on your character too.",
			Code = "function MyMove:Enter()\n\tApi.PlaySound(Whoosh)\nend" },
		{ Key = "Api.Sounds(Names)", Value = "-> table",
			Summary = "Every <Name>SoundId of your block loaded at once, by name: SurgeSoundId becomes Sounds.Surge. Pass a table of names to load only some.",
			Code = "local Sounds = Api.Sounds()\n\nfunction MyMove:Enter()\n\tApi.PlaySound(Sounds.Surge)\nend" },
		{ Key = "Api.SetLoop(Sound, On)", Value = "no return",
			Summary = "Starts a sound looping or stops it, replicated like PlaySound, and does nothing when it is already in that state, so it is safe to call every tick.",
			Code = "function MyMove:Update(DeltaTime)\n\tApi.SetLoop(Sounds.Wind, Api.RootPart.AssemblyLinearVelocity.Magnitude > 30)\nend" },
		{ Key = "Api.StopSound(Sound)", Value = "no return",
			Summary = "Stops it everywhere it was started. Use it in Exit for a looping sound.",
			Code = "function MyMove:Exit()\n\tApi.StopSound(Whoosh)\nend" },
	},
}
