return {
	EditMode = {
		Title = "Stop the playtest and go back to Edit mode",
		Detail = "Anything the installer moves while the game is running is thrown away when you stop.",
	},
	Package = {
		Title = function(Name: string, Where: string): string return "Put the \"" .. Name .. "\" package into " .. Where end,
		Found = function(Package: string, Groups: number): string return "Found " .. Package .. " with " .. Groups .. " group(s) to unpack" end,
		Installed = function(Version: string): string return "Ultimate Movement System V" .. Version .. " is installed here, the package is only needed to install or reinstall" end,
		Missing = function(Name: string, Prefix: string, Where: string): string return "Nothing named \"" .. Name .. "\" with \"" .. Prefix .. "\" models inside was found in " .. Where end,
	},
	Destinations = {
		Title = "Fix the destinations the package asks for",
		Detail = function(Unresolved: string): string return "Could not resolve: " .. Unresolved end,
	},
	Sandbox = {
		Title = "Turn off the Sandboxed property on Workspace",
		Detail = "A sandboxed Workspace limits what scripts may do, the uploader included. "
			.. "Select Workspace and untick Sandboxed in the Properties window.",
	},
	Beta = {
		Title = "Turn on the \"CreateAssetAsync Luau API\" beta feature, then restart Studio",
		Detail = "File \226\134\146 Beta Features. Without it the animation uploader cannot publish anything. "
			.. "It only works for locally installed plugins, which this one is.",
	},
}
