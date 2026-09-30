--// [Modules]
local Theme = require(script.Parent.Theme)
local Content = require(script.Parent.Content)
local ConfigReader = require(script.Parent.ConfigReader)
local ConfigScanner = require(script.Parent.ConfigScanner)
local DocPage = require(script.Parent.DocPage)

--// [Variables]
local ConfigDocs = Content.Config.Blocks
local ConfigSettingDocs = Content.Config.Settings
local TabConfig = {}

--// [Do not go past this point]

local function RowFor(Setting, BlockName)
	local Doc = ConfigSettingDocs.For(BlockName .. "." .. Setting.Key) or Content.Library.Setting(BlockName, Setting.Key)
	local HasDoc = Doc ~= nil and Doc.Summary ~= nil and Doc.Summary ~= ""
	local Lines = {}

	if HasDoc then
		table.insert(Lines, { Text = Doc.Summary, Size = 15, Colour = Theme.BodyText })
	elseif Setting.Comment ~= "" then
		table.insert(Lines, { Text = Setting.Comment, Size = 15, Colour = Theme.BodyText })
	else
		table.insert(Lines, { Text = Content.Config.NoSettingDoc, Size = 15, Colour = Theme.MutedText })
	end
	if Doc and Doc.Accepts and Doc.Accepts ~= "" then
		table.insert(Lines, { Text = Content.Config.Accepts(Doc.Accepts), Size = 13, Colour = Theme.MutedText })
	end
	if HasDoc and Setting.Comment ~= "" then
		table.insert(Lines, { Text = Content.Config.OwnComment(Setting.Comment), Size = 13, Colour = Theme.MutedText })
	end

	return {
		Key = Setting.Key,
		Value = Setting.Value,
		Right = Content.Config.LinePrefix .. tostring(Setting.Line),
		Lines = Lines,
	}
end

local function EntryFor(Block)
	local Doc = ConfigDocs.For(Block.Name) or Content.Library.For(Block.Name)
	local Title = Doc and Doc.Title or ConfigDocs.Title(Block.Name)

	local Groups = {}
	for _, Section in Block.Order do
		local Rows = {}
		for _, Setting in Section.Settings do
			table.insert(Rows, RowFor(Setting, Block.Name))
		end
		table.insert(Groups, { Title = Section.Name, Rows = Rows })
	end

	return {
		Name = Block.Name,
		Title = Title,
		Facts = Content.Config.Facts(Block.Count),
		Blurb = Doc and (Doc.Blurb or Doc.Summary) or Content.Config.NoDoc,
		Haystack = Block.Name .. " " .. Title .. " " .. ((Doc and Doc.Summary) or ""),
		Where = Content.Config.Where(Block.Name, Block.Line, Block.LastLine or Block.Line),
		Summary = Doc and Doc.Summary or nil,
		Notes = Doc and Doc.Notes or nil,
		Groups = Groups,
		Count = Block.Count,
	}
end

function TabConfig.Build(Page)
	local Doc = DocPage.New(Page, {
		GridTitle = Content.Config.GridTitle,
		Search = Content.Config.Search,
		Back = Content.Config.Back,
		Notes = Content.Config.Notes,
		ExpandHint = Content.Config.ExpandHint,
	})

	local Entries = {}
	local Refresh

	local function Draw()
		if #Entries == 0 then
			Doc.Draw(Entries)
			Doc.Status.Text = Content.Config.NoConfig
			Doc.Status.TextColor3 = Theme.Warning
			return
		end
		local Shown = Doc.Draw(Entries)
		local Settings = 0
		for _, Entry in Entries do
			Settings += Entry.Count
		end
		Doc.Status.TextColor3 = Theme.MutedText
		Doc.Status.Text = Content.Config.Summary(Shown, #Entries, Settings)
	end

	local Watching, Watch = nil, nil
	local Waiting = false

	Refresh = function()
		Entries = {}
		for _, Block in ConfigReader.Read() or {} do
			table.insert(Entries, EntryFor(Block))
		end
		Draw()
		if not Doc.Reopen(Entries) then
			Doc.Close()
		end

		local Module = ConfigScanner.Module()
		if Module ~= Watching then
			if Watch then
				Watch:Disconnect()
				Watch = nil
			end
			Watching = Module
			if Module then
				Watch = Module:GetPropertyChangedSignal("Source"):Connect(function()

					if Waiting or not Page.Visible then
						return
					end
					Waiting = true
					task.delay(0.35, function()
						Waiting = false
						if Page.Visible then
							Refresh()
						end
					end)
				end)
			end
		end
	end

	Doc.Search:GetPropertyChangedSignal("Text"):Connect(Draw)
	Refresh()
	return Refresh
end

return TabConfig
