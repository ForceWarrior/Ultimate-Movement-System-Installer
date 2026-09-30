--// [Services]
local AssetService = game:GetService("AssetService")
local GroupService = game:GetService("GroupService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local ServerStorage = game:GetService("ServerStorage")
local StudioService = game:GetService("StudioService")

--// [Modules]
local ConfigScanner = require(script.Parent.ConfigScanner)

--// [Variables]
local AnimationUploader = {}
local BaseDelay = 0.1
local BackoffDelay = 2.2
local WorkersPerRig = 4
local Attempts = 4
local EaseAfter = 6
local UploadSeconds = 2
local RateLimitWords = { "limit", "too many", "429", "throttl", "rate exceeded", "try again" }

--// [Do not go past this point]

function AnimationUploader.LooksThrottled(Problem)
	if not Problem then
		return false
	end
	local Low = tostring(Problem):lower()
	for _, Word in RateLimitWords do
		if Low:find(Word, 1, true) then
			return true
		end
	end
	return false
end

local LooksThrottled = AnimationUploader.LooksThrottled

function AnimationUploader.DistinctClips(Jobs)
	local Seen, Total = {}, 0
	for _, Job in Jobs do
		for _, Clip in (Job.Clips or { Job.Clip }) do
			local Key = Clip.Rig .. "|" .. Clip.Name
			if not Seen[Key] then
				Seen[Key] = true
				Total += 1
			end
		end
	end
	return Total
end

function AnimationUploader.Destinations()

	local List = { { Label = "My account", Short = "my account", CreatorType = Enum.AssetCreatorType.User } }

	local Ok, UserId = pcall(function()
		return StudioService:GetUserId()
	end)
	if not Ok or not UserId or UserId == 0 then
		return List
	end

	local Fetched, Groups = pcall(function()
		return GroupService:GetGroupsAsync(UserId)
	end)
	if not Fetched or typeof(Groups) ~= "table" then
		return List
	end

	table.sort(Groups, function(Left, Right)
		return (Left.Rank or 0) > (Right.Rank or 0)
	end)

	local OwnedRank = 255
	local StaffRank = 200

	for _, Group in Groups do
		local Rank = Group.Rank or 0
		local Owns = Rank >= OwnedRank
		local Staff = Rank >= StaffRank
		local RunsThisPlace = game.CreatorType == Enum.CreatorType.Group and Group.Id == game.CreatorId

		if Owns or Staff or RunsThisPlace then
			local Note = Owns and "owner" or (Group.Role or "staff")
			if RunsThisPlace then
				Note = Note .. ", owns this place"
			end
			table.insert(List, {
				Label = Group.Name .. "  (" .. Note .. ")",
				Short = Group.Name,
				CreatorType = Enum.AssetCreatorType.Group,
				CreatorId = Group.Id,
				Rank = Rank,
				RunsThisPlace = RunsThisPlace,
			})
		end
	end

	for Index, Entry in List do
		if Entry.RunsThisPlace then
			table.remove(List, Index)
			table.insert(List, 1, Entry)
			break
		end
	end
	return List
end

function AnimationUploader.LaneCount(Jobs)
	local Rigs, Total = {}, 0
	for _, Job in Jobs do
		for _, Clip in (Job.Clips or { Job.Clip }) do
			if not Rigs[Clip.Rig] then
				Rigs[Clip.Rig] = true
				Total += 1
			end
		end
	end
	return math.max(Total, 1)
end

function AnimationUploader.Estimate(Count, Lanes)
	return math.max(1, math.ceil(Count * (BaseDelay + UploadSeconds) / (WorkersPerRig * math.max(Lanes or 1, 1))))
end

function AnimationUploader.UploadOne(Clip, Destination)
	local Params = {
		Name = Clip.Name,
		Description = "Uploaded by the Ultimate Movement System installer",
		CreatorType = Destination.CreatorType,
	}
	if Destination.CreatorId then
		Params.CreatorId = Destination.CreatorId
	end

	local Ok, Result, Id = pcall(function()
		return AssetService:CreateAssetAsync(Clip.Instance, Enum.AssetType.Animation, Params)
	end)

	if not Ok then
		local Problem = tostring(Result)
		return nil, Problem, not LooksThrottled(Problem)
	end
	if Result ~= Enum.CreateAssetResult.Success then
		return nil, tostring(Id or Result), Result == Enum.CreateAssetResult.PermissionDenied
	end
	return Id, nil, false
end

function AnimationUploader.Upload(Jobs, Destination, OnStep, Cancelled)
	local Assignments, Failures = {}, {}

	local Queue, Seen = {}, {}
	for _, Job in Jobs do
		for _, Clip in (Job.Clips or { Job.Clip }) do
			local Key = Clip.Rig .. "|" .. Clip.Name
			if not Seen[Key] then
				Seen[Key] = true
				table.insert(Queue, { Key = Key, Clip = Clip })
			end
		end
	end

	local Lanes, LaneOrder = {}, {}
	for _, Entry in Queue do
		local Rig = Entry.Clip.Rig
		local Lane = Lanes[Rig]
		if not Lane then
			Lane = { Rig = Rig, Items = {}, Next = 1 }
			Lanes[Rig] = Lane
			table.insert(LaneOrder, Lane)
		end
		table.insert(Lane.Items, Entry)
	end

	local Cache = {}
	local Total = #Queue
	local Done, Running = 0, 0
	local Stop = false

	local Delay = BaseDelay
	local Clean = 0

	local function Slower()
		Delay = math.min(Delay > BaseDelay and Delay * 2 or BackoffDelay, BackoffDelay * 4)
		Clean = 0
	end

	local function Faster()
		Clean += 1
		if Clean >= EaseAfter and Delay > BaseDelay then
			Delay = math.max(BaseDelay, Delay / 2)
			Clean = 0
		end
	end

	local function Publish(Clip)
		local Id, Problem, Fatal
		for Attempt = 1, Attempts do
			Id, Problem, Fatal = AnimationUploader.UploadOne(Clip, Destination)
			if Id or Fatal or not LooksThrottled(Problem) then
				break
			end
			Slower()
			if Attempt < Attempts then
				task.wait(BackoffDelay * 2 ^ (Attempt - 1))
			end
			if Stop or (Cancelled and Cancelled()) then
				break
			end
		end
		return Id, Problem, Fatal
	end

	local function Work(Lane)
		while true do
			if Stop or (Cancelled and Cancelled()) then
				break
			end
			local Index = Lane.Next
			if Index > #Lane.Items then
				break
			end
			Lane.Next += 1
			local Entry = Lane.Items[Index]

			local Id, Problem, Fatal = Publish(Entry.Clip)

			Cache[Entry.Key] = Id or false
			Done += 1
			if Id then
				Faster()
			else
				table.insert(Failures, Lane.Rig .. " " .. Entry.Clip.Name .. ": " .. Problem)
			end
			if OnStep then
				OnStep(Done, Total, Lane.Rig .. "  " .. Entry.Clip.Name, Id, Problem)
			end
			if Fatal then
				table.insert(Failures, "stopped there, the rest were not attempted")
				Stop = true
				break
			end

			task.wait(Delay)
		end
	end

	for _, Lane in LaneOrder do
		local Width = math.clamp(WorkersPerRig, 1, math.max(#Lane.Items, 1))
		Running += Width
		for _ = 1, Width do
			task.spawn(function()
				local Ok, Err = pcall(Work, Lane)
				if not Ok then
					table.insert(Failures, "worker stopped: " .. tostring(Err))
				end
				Running -= 1
			end)
		end
	end

	while Running > 0 do
		task.wait(0.05)
	end

	for _, Job in Jobs do
		local Clips = Job.Clips or { Job.Clip }
		local Ids = {}
		for _, Clip in Clips do
			local Value = Cache[Clip.Rig .. "|" .. Clip.Name]
			if Value then
				table.insert(Ids, tostring(Value))
			end
		end

		if #Ids == #Clips then
			Assignments[Job.Path] = #Ids > 1 and ("{ " .. table.concat(Ids, ", ") .. " }") or Ids[1]
		end
	end
	return Assignments, Failures, Total
end

function AnimationUploader.Backup(Module)
	local Copy = Module:Clone()
	Copy.Name = Module.Name .. "_InstallerBackup"
	local Previous = ServerStorage:FindFirstChild(Copy.Name)
	if Previous then
		Previous.Parent = nil
	end
	Copy.Parent = ServerStorage
	return Copy
end

function AnimationUploader.WriteBack(Assignments, Expected)
	local Module = ConfigScanner.Module()
	if not Module then
		return false, "MovementConfig not found."
	end

	local Before = ConfigScanner.SelfTest(Module.Source)
	if not Before.Trustworthy then
		return false, "Refused: the config scan does not round trip, so nothing was written."
	end

	AnimationUploader.Backup(Module)

	local Wrote, Reason = false, "the config changed under the edit, nothing was written"
	local Skipped, Applied, Sample = {}, 0, nil
	ScriptEditorService:UpdateSourceAsync(Module, function(Old)
		local Rows = ConfigScanner.Scan(Old)
		if #Rows ~= Before.Count then
			return nil
		end

		local ByPath, Values = {}, {}
		for _, Row in Rows do
			ByPath[Row.Path] = Row
			Values[Row.Path] = Row.Raw
		end

		table.clear(Skipped)
		Applied = 0

		for Path, NewValue in Assignments do
			local Row = ByPath[Path]
			local Value = NewValue
			local WantsList = Row and Row.Raw:sub(1, 1) == "{"
			local PlainNumber = Value:match("^%d+$") ~= nil
			local NumberList = Value:match("^{%s*%d[%d%s,]*}$") ~= nil

			if WantsList and PlainNumber then
				Value = "{ " .. Value .. " }"
				NumberList, PlainNumber = true, false
			end

			local Trouble
			if not Row then
				Trouble = "is not in the config any more"
			elseif Expected and Expected[Path] and Row.Raw ~= Expected[Path] then
				Trouble = "changed since you approved it"
			elseif not PlainNumber and not NumberList then
				Trouble = "got a value that is neither an id nor a list of ids"
			elseif WantsList ~= NumberList then
				Trouble = "holds a single id and the clips matched to it gave " .. select(2, Value:gsub("%d+", ""))
			end

			if Trouble then
				table.insert(Skipped, Path .. " " .. Trouble)
			else
				Values[Path] = Value
				Applied += 1
				Sample = Sample or Value:match("%d+")
			end
		end

		if Applied == 0 then
			Reason = #Skipped > 0 and Skipped[1] or "nothing could be written"
			return nil
		end

		local Candidate = ConfigScanner.Splice(Old, Rows, Values)
		local Check = ConfigScanner.Scan(Candidate)
		if #Check ~= #Rows then
			return nil
		end
		for Index, Row in Check do
			if Row.Path ~= Rows[Index].Path then
				return nil
			end
		end
		local _, OldLines = Old:gsub("\n", "")
		local _, NewLines = Candidate:gsub("\n", "")
		if OldLines ~= NewLines then
			return nil
		end

		Wrote = true
		return Candidate
	end)

	if not Wrote then
		return false, Reason, Skipped
	end

	if Sample then
		for _ = 1, 60 do
			if Module.Source:find(Sample, 1, true) then
				break
			end
			task.wait(0.05)
		end
	end
	return true, nil, Skipped, Applied
end

return AnimationUploader
