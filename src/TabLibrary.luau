--// [Modules]
local Theme = require(script.Parent.Theme)
local Content = require(script.Parent.Content)
local DocPage = require(script.Parent.DocPage)
local Library = require(script.Parent.Library)

--// [Variables]
local TabLibrary = {}

--// [Do not go past this point]

local function RowFor(Row)
	local Lines = { { Text = Row.Summary, Size = 13, Colour = Theme.BodyText } }
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

local function SettingsGroup(Settings)
	local Keys = {}
	for Key in Settings do
		table.insert(Keys, Key)
	end
	table.sort(Keys)
	local Rows = {}
	for _, Key in Keys do
		table.insert(Rows, RowFor({ Key = Key, Value = Settings[Key].Accepts, Summary = Settings[Key].Summary }))
	end
	return { Title = Content.Library.SettingsTitle, Rows = Rows }
end

local function EntryFor(Entry, Plan, Action)
	local Groups, Pieces = {}, { Entry.Title, Entry.Blurb or "", Entry.Summary or "" }
	for _, Group in Entry.Groups or {} do
		local Rows = {}
		for _, Row in Group.Rows do
			table.insert(Rows, RowFor(Row))
			table.insert(Pieces, Row.Key)
			table.insert(Pieces, Row.Summary or "")
		end
		table.insert(Groups, { Title = Group.Title, Rows = Rows })
	end
	if Entry.Settings then
		local Group = SettingsGroup(Entry.Settings)
		for _, Row in Group.Rows do
			table.insert(Pieces, Row.Key)
		end
		table.insert(Groups, Group)
	end
	return {
		Name = Entry.Name,
		Title = Entry.Title,
		Facts = if Plan then Content.Library.Facts(Plan.Count) else Content.Library.BuiltIn,
		Blurb = Entry.Blurb,
		Haystack = table.concat(Pieces, " "),
		Summary = Entry.Summary,
		Notes = Entry.Notes,
		Groups = Groups,
		Action = Action,
	}
end

function TabLibrary.Build(Page)
	local Doc = DocPage.New(Page, {
		GridTitle = Content.Library.GridTitle,
		Search = Content.Library.Search,
		Back = Content.Library.Back,
		Notes = Content.Library.Notes,
		ExpandHint = Content.Library.ExpandHint,
	})

	local InsertConfirm = Theme.Confirm(Page, 84, Content.Library.InsertYes, Content.Library.ConfirmNo)
	local RemoveConfirm = Theme.Confirm(Page, 84, Content.Library.RemoveYes, Content.Library.ConfirmNo)
	local Done = Theme.Notice(Page, 86, Content.Library.DoneClose)
	local Refresh

	local function Run(Entry)
		local Plan = Library.Plan(Entry.Name)
		if Plan.Problem then
			Done.Show(Content.Library.FailedTitle, Plan.Problem)
			return
		end
		local Removing = Plan.Present
		local Confirm = if Removing then RemoveConfirm else InsertConfirm
		local Title = if Removing then Content.Library.RemoveTitle(Entry.Title) else Content.Library.InsertTitle(Entry.Title)
		local Warning = if #Plan.Warnings > 0 then table.concat(Plan.Warnings, "\n") else nil
		Confirm.Show(Title, table.concat(Plan.Lines, "\n"), function()
			local Change = if Removing then Library.Remove else Library.Insert
			local Ok, Said = Change(Plan)
			if Ok then
				Done.Show(if Removing then Content.Library.RemovedTitle else Content.Library.DoneTitle, table.concat(Said, "\n"))
			else
				Done.Show(Content.Library.FailedTitle, Said)
			end
			Refresh()
		end, Warning)
	end

	local InsertAction = { Text = Content.Library.Insert, Run = Run }
	local RemoveAction = { Text = Content.Library.Remove, Run = Run }

	local Entries = {}
	local function Draw()
		local Shown = Doc.Draw(Entries)
		if Doc.Search.Text == "" then
			Doc.Status.Text = Content.Library.Status
		else
			Doc.Status.Text = Content.Library.Summary(Shown, #Entries)
		end
	end

	Refresh = function()
		table.clear(Entries)
		for _, Entry in Content.Library.Entries do
			local Plan = Library.Plan(Entry.Name)
			local Action = if not Plan then nil elseif Plan.Present then RemoveAction else InsertAction
			table.insert(Entries, EntryFor(Entry, Plan, Action))
		end
		Draw()
		if not Doc.Reopen(Entries) then
			Doc.Close()
		end
	end

	Doc.Search:GetPropertyChangedSignal("Text"):Connect(Draw)
	Refresh()
	return Refresh
end

return TabLibrary
