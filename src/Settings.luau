--// [Variables]
local Settings = {}

--// [Do not go past this point]

Settings.Versions = {
	{ Value = "1", Label = "V1", PackageName = "Ultimate Movement System V1" },
}
Settings.Version = Settings.Versions[1]

Settings.PackageName = "Ultimate Movement System"
Settings.UngroupPrefix = "UNGROUP IN "
Settings.SearchIn = { "Workspace" }
Settings.ConfigPath = "ReplicatedStorage.Modules.Movement.MovementConfig"
Settings.AnimationFolderName = "UploadedAnimations"

Settings.InstalledSuffix = " (installed, safe to delete)"
Settings.AnimationSourceName = "Animations (Delete after use)"
Settings.AnimationRigs = { "R6", "R15" }
Settings.ExcludeSources = { "RBX_ANIMSAVES", "MoonAnimator2Saves" }

function Settings.Choose(Value)
	for _, Entry in Settings.Versions do
		if Entry.Value == Value then
			Settings.Version = Entry
			return Entry
		end
	end
	return nil
end

function Settings.Get(Key)
	local Own = Settings.Version[Key]
	if Own ~= nil then
		return Own
	end
	return Settings[Key]
end

return Settings
