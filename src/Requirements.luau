--// [Services]
local RunService = game:GetService("RunService")

--// [Modules]
local Settings = require(script.Parent.Settings)
local Content = require(script.Parent.Content)
local ConfigScanner = require(script.Parent.ConfigScanner)
local KitVersion = require(script.Parent.KitVersion)

--// [Variables]
local Requirements = {}
local AcknowledgeKey = "UMSInstaller_BetaAcknowledged"
local PluginHandle = nil
local Aliases = {
	StarterPlayerScripts = { "StarterPlayer", "StarterPlayerScripts" },
	StarterCharacterScripts = { "StarterPlayer", "StarterCharacterScripts" },
	PlayerScripts = { "StarterPlayer", "StarterPlayerScripts" },
	CharacterScripts = { "StarterPlayer", "StarterCharacterScripts" },
}

--// [Do not go past this point]

function Requirements.Attach(Handle)
	PluginHandle = Handle
end

function Requirements.ResolvePath(Path)
	local Steps = Aliases[Path]
	if not Steps then
		Steps = {}
		for Piece in Path:gmatch("[^%.]+") do
			Steps[#Steps + 1] = Piece
		end
	end

	local Node = game
	for Index, Name in Steps do
		local Next = Node:FindFirstChild(Name)
		if Next == nil and Index == 1 then
			local Ok, Service = pcall(function()
				return game:GetService(Name)
			end)
			Next = Ok and Service or nil
		end
		if Next == nil then
			return nil, Name
		end
		Node = Next
	end
	return Node
end

function Requirements.FindPackage()
	local Wanted = Settings.Get("PackageName")
	local Prefix = Settings.Get("UngroupPrefix")

	local function Qualifies(Node)
		if Node.Name:sub(1, #Wanted) ~= Wanted then
			return false
		end
		for _, Child in Node:GetChildren() do
			if Child.Name:sub(1, #Prefix) == Prefix then
				return true
			end
		end
		return false
	end

	for _, ServiceName in Settings.Get("SearchIn") do
		local Container = Requirements.ResolvePath(ServiceName)
		if Container then
			for _, Child in Container:GetChildren() do
				if Qualifies(Child) then
					return Child
				end
			end
		end
	end
	return nil
end

function Requirements.Optionals(Package)
	local Prefix = Settings.Get("UngroupPrefix")
	local Found = {}
	if Package == nil then
		return Found
	end
	for _, Child in Package:GetChildren() do
		if Child.Name:sub(1, #Prefix) ~= Prefix then
			local Count = 0
			for _, Inner in Child:GetChildren() do
				if Inner.Name:sub(1, #Prefix) == Prefix then
					Count += 1
				end
			end
			if Count > 0 then
				table.insert(Found, { Name = Child.Name, Group = Child, Count = Count })
			end
		end
	end
	return Found
end

local function Entry(Child, Prefix, Optional)
	local Path = Child.Name:sub(#Prefix + 1)
	local Target, Missing = Requirements.ResolvePath(Path)
	return {
		Source = Child,
		Path = Path,
		Target = Target,
		Missing = Missing,
		Count = #Child:GetChildren(),
		Optional = Optional,
	}
end

function Requirements.ReadPlan(Package, Extras)
	local Prefix = Settings.Get("UngroupPrefix")
	local Plan = {}
	if Package == nil then
		return Plan
	end

	for _, Child in Package:GetChildren() do
		if Child.Name:sub(1, #Prefix) == Prefix then
			Plan[#Plan + 1] = Entry(Child, Prefix, nil)
		end
	end
	for _, Optional in Requirements.Optionals(Package) do
		if Extras and Extras[Optional.Name] then
			for _, Child in Optional.Group:GetChildren() do
				if Child.Name:sub(1, #Prefix) == Prefix then
					Plan[#Plan + 1] = Entry(Child, Prefix, Optional.Group)
				end
			end
		end
	end
	return Plan
end

function Requirements.BetaAcknowledged()
	return PluginHandle ~= nil and PluginHandle:GetSetting(AcknowledgeKey) == true
end

function Requirements.AcknowledgeBeta(State)
	if PluginHandle then
		PluginHandle:SetSetting(AcknowledgeKey, State and true or false)
	end
end

function Requirements.Check()
	local Where = table.concat(Settings.Get("SearchIn"), ", ")
	local Results = {}

	Results[#Results + 1] = {
		Title = Content.Requirements.EditMode.Title,
		Detail = Content.Requirements.EditMode.Detail,
		Passed = not RunService:IsRunning(),
		Manual = false,
	}

	local Package = Requirements.FindPackage()
	local Plan = Requirements.ReadPlan(Package)
	local Unresolved = {}
	for _, Entry in Plan do
		if Entry.Target == nil then
			Unresolved[#Unresolved + 1] = Entry.Path
		end
	end

	local Installed = ConfigScanner.Module() ~= nil
	local Detail
	if Package then
		Detail = Content.Requirements.Package.Found(Package:GetFullName(), #Plan)
	elseif Installed then
		Detail = Content.Requirements.Package.Installed((KitVersion.Live()))
	else
		Detail = Content.Requirements.Package.Missing(Settings.Get("PackageName"), Settings.Get("UngroupPrefix"), Where)
	end
	Results[#Results + 1] = {
		Title = Content.Requirements.Package.Title(Settings.Get("PackageName"), Where),
		Detail = Detail,
		Passed = Installed or (Package ~= nil and #Plan > 0),
		Manual = false,
	}

	if Package ~= nil and #Unresolved > 0 then
		Results[#Results + 1] = {
			Title = Content.Requirements.Destinations.Title,
			Detail = Content.Requirements.Destinations.Detail(table.concat(Unresolved, ", ")),
			Passed = false,
			Manual = false,
		}
	end

	local SandboxRead, Sandboxed = pcall(function()
		return workspace.Sandboxed
	end)
	Results[#Results + 1] = {
		Title = Content.Requirements.Sandbox.Title,
		Detail = Content.Requirements.Sandbox.Detail,
		Passed = not SandboxRead or Sandboxed == false,
		Manual = false,
	}

	Results[#Results + 1] = {
		Title = Content.Requirements.Beta.Title,
		Detail = Content.Requirements.Beta.Detail,
		Passed = Requirements.BetaAcknowledged(),
		Manual = true,
	}

	return Results
end

function Requirements.Blocking(Results)
	local Failed = {}
	for _, Entry in Results do
		if not Entry.Passed then
			Failed[#Failed + 1] = Entry
		end
	end
	return Failed
end

return Requirements
