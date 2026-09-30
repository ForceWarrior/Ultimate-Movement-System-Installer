return {
	Name = "Frame",
	Title = "Per frame work",
	Blurb = "The one correct way to run every frame",
	Summary = "Your Update already runs every tick while your move is active. For work that must keep running, bind it to the kit's shared loop with FrameLoop.BindFrame, keep the handle, and disconnect it in Cleanup.",
	Notes = {
		"Update is not this. Update only runs while your move owns the body.",
		"BindFrame runs at Core.UpdatesPerSecond, on the same tick as the moves. BindRender runs every drawn frame, right after the camera, and is only for camera and visual work.",
		"Both ride on callbacks the kit already has: one Heartbeat that belongs to MovementController and one render step that belongs to MovementExtras. Your work never adds a callback to the Rate column of Script Activity.",
		"A binding outlives the character. Disconnect it in Cleanup, or the old callback keeps running after every respawn.",
	},
	Rows = {
		{ Key = "FrameLoop.BindFrame", Value = "the shared loop",
			Summary = "Name, Order, Callback. A lower Order runs first. Returns a handle with Disconnect. It is reachable from the Movement folder without going through the Api.",
			Code = "local FrameLoop = require(\n\tscript:FindFirstAncestor(\"Movement\").Engine.FrameLoop)\n\nlocal Watcher = nil\n\nfunction MyMove:Init(NewApi)\n\tself:Cleanup()\n\tApi = NewApi\n\tWatcher = FrameLoop.BindFrame(\"MyMoveWatcher\", 50, function(DeltaTime)\n\t\t-- runs every tick, whether or not the move is active\n\tend)\nend\n\nfunction MyMove:Cleanup()\n\tif Watcher then Watcher.Disconnect() end\n\tWatcher = nil\nend" },
		{ Key = "FrameLoop.BindRender", Value = "every drawn frame",
			Summary = "Same arguments and handle as BindFrame. Use it for work you can see on screen, like camera or first person visuals. It stops while the window is not being drawn.",
			Code = "Shaker = FrameLoop.BindRender(\"MyMoveShake\", 45, function(DeltaTime)\n\t-- runs once per drawn frame, after the camera\nend)" },
		{ Key = "RunService.Heartbeat", Value = "do not",
			Summary = "Your own connection is a second callback every frame on top of the kit's, and it keeps running after the system has been torn down, which is a leak per respawn.",
			Code = "-- no\nRunService.Heartbeat:Connect(function(DeltaTime)\n\tSomething()\nend)\n\n-- yes\nWatcher = FrameLoop.BindFrame(\"MyMoveWatcher\", 50, function(DeltaTime)\n\tSomething()\nend)" },
	},
}
