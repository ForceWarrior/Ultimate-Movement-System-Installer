--// [Services]
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")

--// [Modules]
local Settings = require(script.Parent.Settings)
local Requirements = require(script.Parent.Requirements)
local ConfigScanner = require(script.Parent.ConfigScanner)

--// [Variables]
local Installer = {}

--// [Do not go past this point]

function Installer.Installed()
	return ConfigScanner.Module() ~= nil
end

function Installer.Preview(Extras)
	local Package = Requirements.FindPackage()
	if not Package then
		return nil, {}
	end

	local Plan = Requirements.ReadPlan(Package, Extras)
	for _, Entry in Plan do
		Entry.Collisions = {}
		Entry.Fresh = {}
		for _, Child in Entry.Source:GetChildren() do
			if Entry.Target and Entry.Target:FindFirstChild(Child.Name) then
				table.insert(Entry.Collisions, Child.Name)
			else
				table.insert(Entry.Fresh, Child.Name)
			end
		end
	end
	return Package, Plan
end

function Installer.CollisionCount(Plan)
	local Total = 0
	for _, Entry in Plan do
		Total += #Entry.Collisions
	end
	return Total
end

function Installer.Run(Overwrite, Extras)
	local Package, Plan = Installer.Preview(Extras)
	local Log = {}

	if RunService:IsRunning() then
		return false, { "Refused: stop the playtest first, nothing moved during a run survives it." }
	end
	if not Package then
		return false, { "Nothing installed: no package found." }
	end
	if #Plan == 0 then
		return false, { "Nothing installed: the package holds no groups to unpack." }
	end

	local Recording = ChangeHistoryService:TryBeginRecording("UMSInstall", "Install Ultimate Movement System")

	local Moved, Kept, Replaced, Refused = 0, 0, 0, 0
	local Emptied = {}

	for _, Entry in Plan do
		if not Entry.Target then
			Refused += 1
			table.insert(Log, "refused " .. Entry.Path .. ", no such destination")
			continue
		end

		for _, Child in Entry.Source:GetChildren() do
			local Existing = Entry.Target:FindFirstChild(Child.Name)
			if Existing and not Overwrite then
				Kept += 1
			else
				if Existing then
					Existing.Parent = nil
					Replaced += 1
				end
				Child.Parent = Entry.Target
				Moved += 1
			end
		end

		if #Entry.Source:GetChildren() == 0 then
			table.insert(Emptied, Entry.Source)
		end
	end

	table.insert(Log, "moved " .. Moved .. ", left " .. Kept .. " of yours alone, replaced " .. Replaced .. ", refused " .. Refused)
	if Kept > 0 then
		table.insert(Log, "your copies were kept; use Replace mine if you meant to overwrite them")
	end

	for _, Group in Emptied do
		Group.Parent = nil
	end
	if #Emptied > 0 then
		table.insert(Log, "removed " .. #Emptied .. " emptied group(s)")
	end

	local Prefix = Settings.Get("UngroupPrefix")
	for _, Entry in Plan do
		local Group = Entry.Optional
		if Group and Group.Parent then
			local Left = 0
			for _, Child in Group:GetChildren() do
				if Child.Name:sub(1, #Prefix) == Prefix then
					Left += 1
				end
			end
			if Left == 0 then
				Group.Parent = nil
				table.insert(Log, Group.Name .. " is unpacked and removed")
			end
		end
	end

	local Left = #Package:GetChildren()
	if Left == 0 and not Package.Name:find(Settings.InstalledSuffix, 1, true) then
		Package.Name = Package.Name .. Settings.InstalledSuffix
		table.insert(Log, "the package is empty and renamed to \"" .. Package.Name .. "\", delete it when you are happy")
	elseif Left > 0 then
		table.insert(Log, Left .. " item(s) still in the package, left untouched")
	end

	if Recording then
		ChangeHistoryService:FinishRecording(Recording, Enum.FinishRecordingOperation.Commit)
	end
	return Refused == 0, Log
end

return Installer
