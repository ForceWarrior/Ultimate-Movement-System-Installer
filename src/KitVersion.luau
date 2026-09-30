--// [Modules]
local ConfigScanner = require(script.Parent.ConfigScanner)

--// [Variables]
local KitVersion = {}

--// [Do not go past this point]

KitVersion.Attribute = "Version"
KitVersion.Unknown = "unknown"

local function ReadNode(Movement)
	if not Movement then
		return nil
	end

	local Stamp = Movement:GetAttribute(KitVersion.Attribute)
	if typeof(Stamp) == "string" and Stamp ~= "" then
		return Stamp, "attribute"
	end
	if typeof(Stamp) == "number" then
		return tostring(Stamp), "attribute"
	end

	local Config = Movement:FindFirstChild("MovementConfig")
	if Config and Config:IsA("LuaSourceContainer") then
		local OnConfig = Config:GetAttribute(KitVersion.Attribute)
		if typeof(OnConfig) == "string" and OnConfig ~= "" then
			return OnConfig, "attribute"
		end
		local Line = Config.Source:match("SystemVersion%s*=%s*\"([^\"]+)\"")
		if Line then
			return Line, "config"
		end
	end

	local Api = Movement:FindFirstChild("MovementApi")
	if Api and Api:IsA("LuaSourceContainer") then
		local Line = Api.Source:match("SystemVersion%s*=%s*\"([^\"]+)\"")
		if Line then
			return Line, "source"
		end
	end
	return nil
end

function KitVersion.Live()
	local Config = ConfigScanner.Module()
	local Version, How = ReadNode(Config and Config.Parent)
	return Version or KitVersion.Unknown, How
end

function KitVersion.Package(Package)
	local Config = Package and Package:FindFirstChild("MovementConfig", true)
	local Version, How = ReadNode(Config and Config.Parent)
	return Version or KitVersion.Unknown, How
end

function KitVersion.AtLeast(Have, Want)
	if typeof(Have) ~= "string" or typeof(Want) ~= "string" then
		return false
	end
	local Mine, Theirs = {}, {}
	for Piece in Have:gmatch("%d+") do
		table.insert(Mine, tonumber(Piece))
	end
	for Piece in Want:gmatch("%d+") do
		table.insert(Theirs, tonumber(Piece))
	end
	if #Mine == 0 or #Theirs == 0 then
		return false
	end
	for Index = 1, math.max(#Mine, #Theirs) do
		local A, B = Mine[Index] or 0, Theirs[Index] or 0
		if A ~= B then
			return A > B
		end
	end
	return true
end

function KitVersion.Compare(Have, Want)
	if Have == nil or Want == nil or Have == KitVersion.Unknown or Want == KitVersion.Unknown then
		return "unknown"
	end
	if tostring(Have) == tostring(Want) then
		return "same"
	end
	return "different"
end

return KitVersion
