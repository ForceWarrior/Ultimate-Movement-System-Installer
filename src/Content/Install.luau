return {
	FolderHeading = "1. Folders",
	AnimationHeading = "2. Animations",
	AnimationHeadingOnly = "Animations",
	AlreadyInstalled = "Ultimate Movement System is already in this place. Delete it from "
		.. "ReplicatedStorage and the folder step comes back.",
	Button = "Install folders",
	NoPackage = function(Package: string, Places: string): string return "No \"" .. Package .. "\" package found in " .. Places .. "." end,
	Ready = function(Package: string, Groups: number, Replaced: number): string return Package .. ", " .. Groups .. " group(s) to unpack, " .. Replaced .. " item(s) would be replaced" end,
	PlanRow = function(Items: number, Collides: string): string return "moves " .. Items .. " item(s)" .. Collides end,
	PlanUnresolved = "this destination does not exist in this place",
	PlanCollides = function(Kept: number): string return ", " .. Kept .. " of yours already there and kept" end,
	OptionalTick = function(Name: string): string return "Also install the " .. Name end,
	OptionalNote = function(Groups: number): string return Groups .. " group(s) inside, they stay in the package unless ticked" end,
	Overwrite = "Replace mine",
	OverwriteNote = "Only items with the same name as something in the package are replaced. "
		.. "Everything else of yours is left alone.",
	Versions = function(Installed: string, Carried: string): string return "installed V" .. Installed .. ", the package carries V" .. Carried end,
	ReplaceHeading = "Replace the installed kit?",
	ReplaceDifferent = function(Have: string, Want: string): string return "You are replacing V" .. Have .. " with V" .. Want .. ". Are you sure?" end,
	ReplaceSame = function(Have: string): string return "V" .. Have .. " is already installed and the package carries the same version. Replace it anyway?" end,
	ReplaceUnknown = "The version of one side could not be read, so this may be a downgrade. "
		.. "Are you sure?",
	ReplaceYes = "Yes, replace it",
	ReplaceNo = "Keep it",
}
