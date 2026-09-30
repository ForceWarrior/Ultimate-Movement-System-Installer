--// [Modules]
local Theme = require(script.Parent.Theme)
local Content = require(script.Parent.Content)
local DocPage = require(script.Parent.DocPage)

--// [Variables]
local ApiDocs = Content.Api
local TabApi = {}

--// [Do not go past this point]

local function RowFor(Row)
	local Lines = {}
	table.insert(Lines, {
		Text = Row.Summary or Content.Api.NoEntryDoc,
		Size = 13,
		Colour = Row.Summary and Theme.BodyText or Theme.MutedText,
	})
	if Row.Accepts and Row.Accepts ~= "" then
		table.insert(Lines, { Text = Content.Api.Accepts(Row.Accepts), Size = 12, Colour = Theme.MutedText })
	end
	if Row.Note then
		table.insert(Lines, { Text = Row.Note, Size = 12, Colour = Theme.MutedText })
	end
	return {
		Key = Row.Key,
		Value = Row.Value,
		Lines = Lines,
		Code = Row.Code,
	}
end

local function EntryFor(Section)
	local Rows, Pieces = {}, { Section.Title, Section.Blurb or "", Section.Summary or "" }
	for _, Row in Section.Rows or {} do
		table.insert(Rows, RowFor(Row))
		table.insert(Pieces, Row.Key)
		table.insert(Pieces, Row.Summary or "")
	end
	return {
		Name = Section.Name,
		Title = Section.Title,
		Facts = Content.Api.Facts(ApiDocs.Count(Section)),
		Blurb = Section.Blurb,
		Haystack = table.concat(Pieces, " "),
		Summary = Section.Summary,
		Notes = Section.Notes,
		Groups = { { Rows = Rows } },
		Count = #Rows,
	}
end

function TabApi.Build(Page)
	local Doc = DocPage.New(Page, {
		GridTitle = Content.Api.GridTitle,
		Search = Content.Api.Search,
		Back = Content.Api.Back,
		Notes = Content.Api.Notes,
		ExpandHint = Content.Api.ExpandHint,
	})

	local Entries = {}
	for _, Section in ApiDocs.Sections do
		table.insert(Entries, EntryFor(Section))
	end

	local function Draw()
		local Shown = Doc.Draw(Entries)
		if Doc.Search.Text == "" then
			Doc.Status.Text = ApiDocs.Version
		else
			local Total = 0
			for _, Entry in Entries do
				Total += Entry.Count
			end
			Doc.Status.Text = Content.Api.Summary(Shown, #Entries, Total)
		end
	end

	local function Refresh()
		Draw()
		if not Doc.Reopen(Entries) then
			Doc.Close()
		end
	end

	Doc.Search:GetPropertyChangedSignal("Text"):Connect(Draw)
	Refresh()
	return Refresh
end

return TabApi
