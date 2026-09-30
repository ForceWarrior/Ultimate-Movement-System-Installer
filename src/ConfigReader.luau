--// [Modules]
local ConfigScanner = require(script.Parent.ConfigScanner)
local Content = require(script.Parent.Content)

--// [Variables]
local ConfigReader = {}

--// [Do not go past this point]

local function Split(Text)
	local Lines = {}
	for Line in Text:gmatch("([^\n]*)\n?") do
		table.insert(Lines, Line)
	end
	return Lines
end

local function BlockDelta(Bare)
	local Delta = 0
	for Word in Bare:gmatch("[%a_][%w_]*") do
		if Word == "function" or Word == "if" or Word == "do" then
			Delta += 1
		elseif Word == "end" then
			Delta -= 1
		end
	end
	return Delta
end

function ConfigReader.Read()
	local Module = ConfigScanner.Module()
	if not Module then
		return nil
	end

	local Source = Module.Source
	local Masked = ConfigScanner.Mask(Source)
	local Plain, Code = Split(Source), Split(Masked)

	local Blocks, Current, Section = {}, nil, nil
	local Stack, Counters = {}, {}
	local InFunction = 0

	for Index, Raw in Plain do
		local Bare = (Code[Index] or ""):gsub("%s+$", "")
		local Trailing = Raw:sub(#Bare + 1):match("^%s*%-%-+%s*(.-)%s*$")

		if InFunction > 0 then
			InFunction += BlockDelta(Bare)
			continue
		end

		local Name = Bare:match("^Config%.([%w_]+)%s*=%s*{")
		if Name then
			Current = {
				Name = Name,
				Line = Index,
				Sections = {},
				Order = {},
				Count = 0,
			}
			Section = nil
			table.clear(Stack)
			table.clear(Counters)
			table.insert(Blocks, Current)

		elseif Current and Bare:match("^}") then
			Current.LastLine = Index
			Current = nil
			Section = nil

		elseif Current then
			local Heading = Trailing and Trailing:match("^//%s*%[(.-)%]")
			if Heading then
				Section = { Name = Heading, Settings = {} }
				Current.Sections[Heading] = Section
				table.insert(Current.Order, Section)

			else

				local _, Opens = Bare:gsub("{", "")
				local _, Closes = Bare:gsub("}", "")
				local Net = Opens - Closes

				local Key = Bare:match("^%s*([%w_]+)%s*=")
				local Value
				if Key then
					local Equals = Bare:find("=", 1, true)
					Value = Raw:sub(Equals + 1, #Bare):match("^%s*(.-),?%s*$")
				end
				local Prefix = #Stack > 0 and (table.concat(Stack, ".") .. ".") or ""

				local function Record(Name, Text)
					if not Section then
						Section = { Name = "Settings", Settings = {} }
						Current.Sections.Settings = Section
						table.insert(Current.Order, Section)
					end
					Current.Count += 1
					table.insert(Section.Settings, {
						Key = Name,
						Value = Text,

						Comment = Trailing or "",
						Line = Index,
					})
				end

				if Value and Value:match("^function%f[%W]") then
					Record(Prefix .. (Key or "Function"), Content.Config.FunctionValue)
					InFunction = BlockDelta(Bare)

				elseif Net == 0 then
					if Key and Value and Value ~= "" then
						Record(Prefix .. Key, Value)
					elseif Bare:match("^%s*{.*}%s*,?%s*$") then

						Current.Entries = Current.Entries or {}
						Current.Entries[Prefix] = (Current.Entries[Prefix] or 0) + 1
						Record(Prefix .. "[" .. Current.Entries[Prefix] .. "]",
							(Raw:match("^%s*(.-),?%s*$")))
					end
				elseif Net > 0 then
					local Opened = Bare:match("^%s*([%w_]+)%s*=%s*{")
					for _ = 1, Net do
						local Name = Opened
						if not Name then

							local Depth = #Stack
							Counters[Depth] = (Counters[Depth] or 0) + 1
							Name = "[" .. Counters[Depth] .. "]"
						end
						table.insert(Stack, Name)
						Counters[#Stack] = 0
						Opened = nil
					end
				else
					for _ = 1, -Net do
						if #Stack > 0 then
							table.remove(Stack)
						end
					end
				end
			end
		end
	end

	return Blocks
end

return ConfigReader
