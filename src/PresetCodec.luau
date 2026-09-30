--// [Variables]
local PresetCodec = {}
local Marker = "UMSP1"
local Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local Ceiling = 65535
local Reverse = {}

--// [Do not go past this point]

for Index = 1, #Alphabet do
	Reverse[Alphabet:sub(Index, Index)] = Index - 1
end

local function ToBase64(Data)
	local Out = table.create(math.ceil(#Data / 3) * 4)
	local Index = 1
	while Index <= #Data do
		local First = string.byte(Data, Index)
		local Second = string.byte(Data, Index + 1)
		local Third = string.byte(Data, Index + 2)
		local Number = First * 65536 + (Second or 0) * 256 + (Third or 0)

		local One = math.floor(Number / 262144) % 64
		local Two = math.floor(Number / 4096) % 64
		local Three = math.floor(Number / 64) % 64
		local Four = Number % 64

		table.insert(Out, Alphabet:sub(One + 1, One + 1))
		table.insert(Out, Alphabet:sub(Two + 1, Two + 1))
		table.insert(Out, Second and Alphabet:sub(Three + 1, Three + 1) or "=")
		table.insert(Out, Third and Alphabet:sub(Four + 1, Four + 1) or "=")
		Index += 3
	end
	return table.concat(Out)
end

local function FromBase64(Text)
	Text = Text:gsub("[^A-Za-z0-9+/=]", "")
	if #Text % 4 ~= 0 then
		return nil
	end

	local Out = table.create(#Text / 4 * 3)
	for Index = 1, #Text, 4 do
		local One = Reverse[Text:sub(Index, Index)]
		local Two = Reverse[Text:sub(Index + 1, Index + 1)]
		local Three = Reverse[Text:sub(Index + 2, Index + 2)]
		local Four = Reverse[Text:sub(Index + 3, Index + 3)]
		if not One or not Two then
			return nil
		end

		local Number = One * 262144 + Two * 4096 + (Three or 0) * 64 + (Four or 0)
		table.insert(Out, string.char(math.floor(Number / 65536) % 256))
		if Three then
			table.insert(Out, string.char(math.floor(Number / 256) % 256))
		end
		if Four then
			table.insert(Out, string.char(Number % 256))
		end
	end
	return table.concat(Out)
end

local function Compress(Input)
	local Dictionary = {}
	for Index = 0, 255 do
		Dictionary[string.char(Index)] = Index
	end

	local Size = 256
	local Codes, Word = {}, ""
	for Index = 1, #Input do
		local Char = Input:sub(Index, Index)
		local Joined = Word .. Char
		if Dictionary[Joined] then
			Word = Joined
		else
			table.insert(Codes, Dictionary[Word])
			if Size < Ceiling then
				Dictionary[Joined] = Size
				Size += 1
			end
			Word = Char
		end
	end
	if Word ~= "" then
		table.insert(Codes, Dictionary[Word])
	end
	return Codes
end

local function Decompress(Codes)
	if #Codes == 0 then
		return ""
	end

	local Dictionary = table.create(Ceiling)
	for Index = 0, 255 do
		Dictionary[Index] = string.char(Index)
	end

	local Size = 256
	local Previous = Dictionary[Codes[1]]
	if not Previous then
		return nil
	end

	local Out = { Previous }
	for Index = 2, #Codes do
		local Code = Codes[Index]
		local Entry
		if Dictionary[Code] then
			Entry = Dictionary[Code]
		elseif Code == Size then
			Entry = Previous .. Previous:sub(1, 1)
		else
			return nil
		end
		table.insert(Out, Entry)
		if Size < Ceiling then
			Dictionary[Size] = Previous .. Entry:sub(1, 1)
			Size += 1
		end
		Previous = Entry
	end
	return table.concat(Out)
end

local function Pack(Codes)
	local Out = table.create(#Codes)
	for _, Code in Codes do
		table.insert(Out, string.char(math.floor(Code / 256), Code % 256))
	end
	return table.concat(Out)
end

local function Unpack(Data)
	if #Data % 2 ~= 0 then
		return nil
	end
	local Codes = table.create(#Data / 2)
	for Index = 1, #Data - 1, 2 do
		table.insert(Codes, string.byte(Data, Index) * 256 + string.byte(Data, Index + 1))
	end
	return Codes
end

local HexDigits = "0123456789abcdef"

local function Hex8(Value: number): string
	local Digits = table.create(8)
	for Place = 8, 1, -1 do
		local Digit = Value % 16
		Digits[Place] = HexDigits:sub(Digit + 1, Digit + 1)
		Value = (Value - Digit) // 16
	end
	return table.concat(Digits)
end

local function Checksum(Text)
	local Sum = 5381
	for Index = 1, #Text do
		Sum = (Sum * 33 + string.byte(Text, Index)) % 4294967296
	end
	return Sum
end

local function BuildPayload(Name, Description, Values, Order, Version)
	local Lines = { "NAME\t" .. Name, "DESC\t" .. Description }

	if Version ~= nil and Version ~= "" then
		table.insert(Lines, "VER\t" .. tostring(Version))
	end
	for _, Path in Order do
		table.insert(Lines, "S\t" .. Path .. "\t" .. Values[Path])
	end
	return table.concat(Lines, "\n")
end

local Constructors = {
	["Color3.new"] = true,
	["Color3.fromRGB"] = true,
	["Color3.fromHSV"] = true,
	["Vector2.new"] = true,
	["Vector3.new"] = true,
	["UDim.new"] = true,
	["UDim2.new"] = true,
	["UDim2.fromScale"] = true,
	["UDim2.fromOffset"] = true,
	["NumberRange.new"] = true,
	["CFrame.new"] = true,
	["CFrame.Angles"] = true,
}

local function TopLevelPieces(Text)
	local Pieces, Depth, Start = {}, 0, 1
	for Index = 1, #Text do
		local Char = Text:sub(Index, Index)
		if Char == "(" then
			Depth += 1
		elseif Char == ")" then
			Depth -= 1
		elseif Char == "," and Depth == 0 then
			table.insert(Pieces, Text:sub(Start, Index - 1))
			Start = Index + 1
		end
	end
	table.insert(Pieces, Text:sub(Start))
	return Pieces
end

local IsLiteral
IsLiteral = function(Text)
	if type(Text) ~= "string" then
		return false
	end

	local Trimmed = Text:match("^%s*(.-)%s*$")
	if Trimmed == "" or #Trimmed > 400 or Trimmed:find("[\n\r]") then
		return false
	end

	if tonumber(Trimmed) then
		return true
	end
	if Trimmed == "true" or Trimmed == "false" or Trimmed == "nil" then
		return true
	end
	if Trimmed:match('^"[^"\\]*"$') or Trimmed:match("^'[^'\\]*'$") then
		return true
	end
	if Trimmed:match("^Enum%.[%w_]+%.[%w_]+$") then
		return true
	end

	local Constructor, Arguments = Trimmed:match("^([%u][%w]*%.[%w]+)%(([%-%d%.%s,e]*)%)$")
	if Constructor and Constructors[Constructor] and not Arguments:find("%a%a") then
		return true
	end

	local Inner = Trimmed:match("^{(.*)}$")
	if Inner then
		if Inner:find("[{}]") then
			return false
		end
		if Inner:match("^%s*$") then
			return true
		end
		for _, Piece in TopLevelPieces(Inner) do
			if Piece:match("%S") then
				local Assigned = Piece:match("^%s*[%w_]+%s*=%s*(.+)$")
				if not IsLiteral(Assigned or Piece) then
					return false
				end
			end
		end
		return true
	end

	return false
end

PresetCodec.IsLiteral = IsLiteral

local function ReadPayload(Text)
	local Name, Description, Values, Version = nil, "", {}, nil
	local Count = 0
	for Line in Text:gmatch("([^\n]+)") do
		local Kind, Rest = Line:match("^(%u+)\t(.*)$")
		if Kind == "NAME" then
			Name = Rest
		elseif Kind == "DESC" then
			Description = Rest
		elseif Kind == "VER" then
			Version = Rest ~= "" and Rest or nil
		elseif Kind == "S" then
			local Path, Value = Rest:match("^([^\t]+)\t(.*)$")
			if Path and Value then
				Values[Path] = Value
				Count += 1
			end
		end
	end
	return Name, Description, Values, Count, Version
end

function PresetCodec.Encode(Name, Description, Values, Order, Version)
	local Payload = BuildPayload(Name, Description, Values, Order, Version)
	local Body = ToBase64(Pack(Compress(Payload)))
	return Marker .. ":" .. Hex8(Checksum(Payload)) .. ":" .. Body, #Payload, #Body
end

function PresetCodec.Decode(Text)
	if type(Text) ~= "string" then
		return nil, "nothing to read"
	end

	local Stamp, Body = Text:match(Marker .. ":(%x%x%x%x%x%x%x%x):([%w%+/=%s]+)")
	if not Stamp then
		return nil, "no preset code found in that text"
	end

	local Packed = FromBase64(Body)
	if not Packed then
		return nil, "the preset code is damaged"
	end

	local Codes = Unpack(Packed)
	if not Codes then
		return nil, "the preset code is damaged"
	end

	local Payload = Decompress(Codes)
	if not Payload then
		return nil, "the preset code is damaged"
	end

	if Hex8(Checksum(Payload)) ~= Stamp then
		return nil, "the preset code did not survive the trip, some of it is missing"
	end

	local Name, Description, Values, Count, Version = ReadPayload(Payload)
	if not Name or Name == "" then
		return nil, "that code carries no preset name"
	end

	for Path, Value in Values do
		if not Path:match("^[%w_%.%[%]]+$") then
			return nil, "that code names a setting oddly (" .. Path:sub(1, 40) .. "), refusing it"
		end
		if not IsLiteral(Value) then
			return nil, Path .. " carries something that is not a plain value, refusing it"
		end
	end

	return {
		Name = Name,
		Description = Description,
		Values = Values,
		Count = Count,
		Version = Version,
	}, nil
end

function PresetCodec.SelfTest(Name, Description, Values, Order, Version)
	local Code = PresetCodec.Encode(Name, Description, Values, Order, Version)
	local Back, Problem = PresetCodec.Decode(Code)
	if not Back then
		return false, Problem
	end
	if Back.Name ~= Name or Back.Description ~= Description then
		return false, "the name or notes did not come back"
	end
	if (Version ~= nil and Version ~= "") and Back.Version ~= tostring(Version) then
		return false, "the version did not come back"
	end
	for _, Path in Order do
		if Back.Values[Path] ~= Values[Path] then
			return false, Path .. " came back as \"" .. tostring(Back.Values[Path]) .. "\""
		end
	end
	for Path in Back.Values do
		if Values[Path] == nil then
			return false, Path .. " appeared out of nowhere"
		end
	end
	return true, nil
end

return PresetCodec
