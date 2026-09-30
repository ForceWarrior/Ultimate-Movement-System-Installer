return [==[
--[[
Made by Force Warrior and Cookie.
Thank you for purchasing!
Reselling or distributing this product in any form or by any means is strictly prohibited.
--]]

--// [Services]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// [Modules]
local MovementTypes = require(script:FindFirstAncestor("Movement").MovementTypes)
local Trove = require(ReplicatedStorage.Modules.Utils.Trove)

--// [Variables]
local Api = nil
local Mode = nil
local Red = nil
local Lifetime = Trove.new()

local EmoteSupport = {}
EmoteSupport.Name = script.Name
EmoteSupport.RequiresApi = 1
EmoteSupport.LocksMovement = true

--// [Do not go past this point]

local function Emote()
	local Character = Api.Character
	local EmoteId = Character:GetAttribute("EmoteId")
	if typeof(EmoteId) ~= "string" then return nil end
	return EmoteId, Character:GetAttribute("EmoteMovement") or "Locked"
end

local function StopEmote()
	if Red == nil then
		local Ok, Module = pcall(require, ReplicatedStorage.Modules.Utils.Red)
		Red = Ok and Module or false
	end
	if Red then
		Red.Client("Emotes"):Fire("Stop")
	end
end

local function Follow()
	if not Api.Character.Parent then return end
	local EmoteId, Movement = Emote()
	if not EmoteId or Movement == "Free" then
		Mode = nil
		if Api.IsActive() then Api.Stop() end
		return
	end
	Mode = Movement
	if Api.IsActive() or Api.Start() then return end

	Api.StopAll()
	if not Api.Start() then
		StopEmote()
	end
end

type Settings = { Enabled: boolean, StopEmoteOnMove: boolean, IgnoredMoves: { string } }

function EmoteSupport:Init(NewApi: MovementTypes.Api<Settings>)
	self:Cleanup()
	Api = NewApi
	for _, Attribute in { "EmoteId", "EmoteMovement" } do
		Lifetime:Add(Api.Character:GetAttributeChangedSignal(Attribute):Connect(Follow))
	end

	Lifetime:Add(Api.OnMoveStarted(function(Name)
		if Name == EmoteSupport.Name or not Api.Config.StopEmoteOnMove then return end
		if Emote() and not table.find(Api.Config.IgnoredMoves, Name) then
			StopEmote()
		end
	end))
	task.defer(Follow)
end

function EmoteSupport:CanEnter(): boolean
	if not Emote() then return Api.Refuse("no emote is playing") end
	return true
end

function EmoteSupport:Enter()
	local Speed = Api.Character:GetAttribute("EmoteSpeed")
	if typeof(Speed) == "number" then Api.Claim("WalkSpeed", Speed) end
end

function EmoteSupport:Exit()
	if Mode and Emote() and Api.Config.StopEmoteOnMove then
		StopEmote()
	end
	Mode = nil
end

function EmoteSupport:OwnsFacing(): boolean
	return Mode == "AutoForward"
end

function EmoteSupport:Cleanup()
	Lifetime:Clean()
	Mode = nil
end

return EmoteSupport
]==]
