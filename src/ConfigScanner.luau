--// [Modules]
local Settings = require(script.Parent.Settings)

--// [Variables]
local ConfigScanner = {}

--// [Do not go past this point]

local function LongBracketLevel(Text, At)
	if Text:sub(At, At) ~= "[" then
		return nil
	end
	local Equals = Text:match("^%[(=*)%[", At)
	return Equals and #Equals or nil
end

function ConfigScanner.Mask(Text)
	local Out = table.create(#Text)
	local Index, Length = 1, #Text

	while Index <= Length do
		local Char = Text:sub(Index, Index)

		if Char == "-" and Text:sub(Index + 1, Index + 1) == "-" then
			local Level = LongBracketLevel(Text, Index + 2)
			if Level then
				local Close = "]" .. string.rep("=", Level) .. "]"
				local Stop = Text:find(Close, Index, true)
				local Finish = Stop and (Stop + #Close - 1) or Length
				for Step = Index, Finish do
					Out[Step] = Text:sub(Step, Step) == "\n" and "\n" or " "
				end
				Index = Finish + 1
			else
				local Stop = Text:find("\n", Index, true) or (Length + 1)
				for Step = Index, Stop - 1 do
					Out[Step] = " "
				end
				Index = Stop
			end

		elseif Char == '"' or Char == "'" then
			local Quote = Char
			Out[Index] = "#"
			Index += 1
			while Index <= Length do
				local Here = Text:sub(Index, Index)
				Out[Index] = Here == "\n" and "\n" or "#"
				if Here == "\\" then
					Index += 1
					if Index <= Length then
						Out[Index] = Text:sub(Index, Index) == "\n" and "\n" or "#"
						Index += 1
					end
				elseif Here == Quote then
					Index += 1
					break
				else
					Index += 1
				end
			end

		elseif Char == "[" and LongBracketLevel(Text, Index) then
			local Level = LongBracketLevel(Text, Index)
			local Close = "]" .. string.rep("=", Level) .. "]"
			local Stop = Text:find(Close, Index, true)
			local Finish = Stop and (Stop + #Close - 1) or Length
			for Step = Index, Finish do
				Out[Step] = Text:sub(Step, Step) == "\n" and "\n" or "#"
			end
			Index = Finish + 1

		else
			Out[Index] = Char
			Index += 1
		end
	end

	return table.concat(Out)
end

local BlockOpeners = { ["function"] = true, ["if"] = true, ["do"] = true }

local function SkipFunction(Mask, Start)
	local Depth = 0
	local Index, Length = Start, #Mask
	while Index <= Length do
		if Mask:sub(Index, Index):match("[%a_]") then
			local Word = Mask:match("^[%w_]+", Index)
			if BlockOpeners[Word] then
				Depth += 1
			elseif Word == "end" then
				Depth -= 1
				if Depth <= 0 then
					return Index + #Word
				end
			end
			Index += #Word
		else
			Index += 1
		end
	end
	return Length + 1
end

local function Walk(Source, Accept, LeavesOnly)
	local Mask = ConfigScanner.Mask(Source)

	local LineAt = table.create(#Source)
	local LineStarts = { 1 }
	local Line = 1
	for Index = 1, #Source do
		LineAt[Index] = Line
		if Source:byte(Index) == 10 then
			Line += 1
			LineStarts[Line] = Index + 1
		end
	end

	local Rows = {}
	local Stack, Counters = {}, {}
	local Pending = nil
	local Paren = 0
	local Index, Length = 1, #Mask

	while Index <= Length do
		local Char = Mask:sub(Index, Index)

		if Char:match("[%a_]") then
			local Word = Mask:match("^[%w_]+", Index)
			if Word == "function" then

				Index = SkipFunction(Mask, Index)
				Pending = nil
			else
				if Mask:match("^%s*=[^=]", Index + #Word) then
					Pending = Word
				end
				Index += #Word
			end

		elseif Char == "[" then

			local From, To = Mask:match("^%[()#+()%]%s*=[^=]", Index)
			if From then
				Pending = Source:sub(From + 1, To - 2)
				Index = To
			else
				Index += 1
			end

		elseif Char == "(" then
			Paren += 1
			Index += 1

		elseif Char == ")" then
			Paren -= 1
			Index += 1

		elseif Char == "{" then
			local Name = Pending
			if not Name then
				local Depth = #Stack
				Counters[Depth] = (Counters[Depth] or 0) + 1
				Name = "[" .. Counters[Depth] .. "]"
			end
			table.insert(Stack, Name)
			Counters[#Stack] = 0
			Pending = nil
			Index += 1

		elseif Char == "}" then
			table.remove(Stack)
			Pending = nil
			Index += 1

		elseif Char == "," then
			if Paren == 0 then
				Pending = nil
			end
			Index += 1

		elseif Char == "=" then
			if Pending and Accept(Pending, Stack) then
				local ValueStart = Index + 1
				while Mask:sub(ValueStart, ValueStart):match("[ \t]") do
					ValueStart += 1
				end

				local Depth, Round, Scan = 0, 0, ValueStart
				while Scan <= Length do
					local Here = Mask:sub(Scan, Scan)
					if Here == "{" then
						Depth += 1
					elseif Here == "}" then
						if Depth == 0 then break end
						Depth -= 1
					elseif LeavesOnly and Here == "(" then
						Round += 1
					elseif LeavesOnly and Here == ")" then
						if Round == 0 then break end
						Round -= 1
					elseif Here == "," and Depth == 0 and Round == 0 then
						break
					elseif Here == "\n" and Depth == 0 then
						break
					end
					Scan += 1
				end
				local ValueEnd = Scan - 1
				while ValueEnd > ValueStart and Mask:sub(ValueEnd, ValueEnd):match("%s") do
					ValueEnd -= 1
				end

				local Raw = Source:sub(ValueStart, ValueEnd)

				local IsFunction = Raw:match("^function%f[%W]") ~= nil
				if not IsFunction
					and not (LeavesOnly and (Raw:find("\n", 1, true) or #Stack == 0 or Raw == "")) then
					local LineStart = LineStarts[LineAt[ValueStart]] or 1
					local LineStop = Source:find("\n", ValueStart) or (#Source + 1)

					table.insert(Rows, {
						Path = table.concat(Stack, ".") .. "." .. Pending,
						Key = Pending,
						Module = Stack[1] or "?",
						Branch = Stack[2],
						Line = LineAt[Index],
						ValueStart = ValueStart,
						ValueEnd = ValueEnd,
						Raw = Raw,
						Text = Source:sub(LineStart, LineStop - 1),
					})
				end
			end
			Index += 1

		else
			Index += 1
		end
	end

	table.sort(Rows, function(Left, Right)
		return Left.ValueStart < Right.ValueStart
	end)

	if LeavesOnly then
		local Kept, Reach = {}, 0
		for _, Row in Rows do
			if Row.ValueStart > Reach then
				table.insert(Kept, Row)
				Reach = Row.ValueEnd
			end
		end
		return Kept
	end

	return Rows
end

local function IsAnimationSlot(Key)
	return Key:sub(-11) == "AnimationId"
end

local function Anything()
	return true
end

function ConfigScanner.Scan(Source)
	return Walk(Source, IsAnimationSlot, false)
end

function ConfigScanner.ScanAll(Source)
	return Walk(Source, Anything, true)
end

function ConfigScanner.Values(Source)
	local Values = {}
	for _, Row in ConfigScanner.ScanAll(Source) do
		Values[Row.Path] = Row.Raw
	end
	return Values
end

function ConfigScanner.Splice(Source, Rows, Values)
	local Ordered = table.clone(Rows)
	table.sort(Ordered, function(Left, Right)
		return Left.ValueStart < Right.ValueStart
	end)

	local Pieces, Cursor = {}, 1
	for _, Row in Ordered do
		table.insert(Pieces, Source:sub(Cursor, Row.ValueStart - 1))
		table.insert(Pieces, Values and Values[Row.Path] or Row.Raw)
		Cursor = Row.ValueEnd + 1
	end
	table.insert(Pieces, Source:sub(Cursor))
	return table.concat(Pieces)
end

function ConfigScanner.SelfTest(Source)
	local Rows = ConfigScanner.Scan(Source)
	local Seen, Duplicates = {}, 0
	for _, Row in Rows do
		if Seen[Row.Path] then
			Duplicates += 1
		end
		Seen[Row.Path] = true
	end
	local Identical = ConfigScanner.Splice(Source, Rows) == Source
	return {
		Rows = Rows,
		Count = #Rows,
		Duplicates = Duplicates,
		Identical = Identical,
		Trustworthy = Identical and Duplicates == 0 and #Rows > 0,
	}
end

function ConfigScanner.LeafSelfTest(Source)
	local Rows = ConfigScanner.ScanAll(Source)
	local Seen, Duplicates = {}, 0
	for _, Row in Rows do
		if Seen[Row.Path] then
			Duplicates += 1
		end
		Seen[Row.Path] = true
	end
	local Identical = ConfigScanner.Splice(Source, Rows) == Source
	return {
		Rows = Rows,
		Count = #Rows,
		Duplicates = Duplicates,
		Identical = Identical,
		Trustworthy = Identical and Duplicates == 0 and #Rows > 0,
	}
end

function ConfigScanner.Module()
	local Node = game
	for Piece in Settings.ConfigPath:gmatch("[^%.]+") do
		Node = Node and Node:FindFirstChild(Piece)
	end
	return Node and Node:IsA("LuaSourceContainer") and Node or nil
end

function ConfigScanner.Value(Row)
	local Number = tonumber(Row.Raw)
	if Number then
		return Number, false
	end
	return nil, Row.Raw:sub(1, 1) == "{"
end

return ConfigScanner
