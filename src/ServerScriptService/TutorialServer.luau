--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService(
		"Players"
	)


local ServerScriptService =
	game:GetService(
		"ServerScriptService"
	)


--==================================================
-- MODULES
--==================================================

local PlayerDataService =
	require(
		ServerScriptService
		:WaitForChild(
			"PlayerDataService"
		)
	)


local TutorialService =
	require(
		ServerScriptService
		:WaitForChild(
			"TutorialService"
		)
	)


--==================================================
-- SETUP PLAYER TUTORIAL
--==================================================

local function SetupPlayer(
	player
)

	--==================================================
	-- WAIT FOR PLAYER DATA
	--==================================================

	-- PlayerDataService may still be loading the
	-- player's profile when PlayerAdded fires.
	--
	-- Wait until the data actually exists before
	-- trying to read tutorial progress.

	local data =
		PlayerDataService.GetData(
			player
		)


	while not data do

		-- Player left while their data was loading.

		if player.Parent
			~= Players then

			return

		end


		task.wait(
			0.1
		)


		data =
			PlayerDataService.GetData(
				player
			)

	end


	--==================================================
	-- RECONNECT RECOVERY
	--==================================================

	-- Tutorial Step 2 means:
	--
	-- "The player rolled a pumpkin and now needs
	-- to buy that active offer."
	--
	-- Active roll offers only exist in server memory
	-- inside PumpkinRollService.
	--
	-- If the player leaves during Step 2, that offer
	-- no longer exists when they join another server.
	--
	-- Therefore Step 2 safely resets back to Step 1.

	if data.TutorialCompleted
		~= true
		and data.TutorialStep
		== TutorialService.STEP_BUY then

		data.TutorialStep =
			TutorialService.STEP_ROLL

	end


	--==================================================
	-- SYNC TUTORIAL
	--==================================================

	local success,
		reason =
		TutorialService.SyncPlayer(
			player
		)


	if not success then

		warn(
			"[TutorialServer] Could not sync tutorial for",
			player.Name,
			reason
		)


		return

	end


	print(
		"[TutorialServer]",
		player.Name,
		"TutorialActive:",
		player:GetAttribute(
			"TutorialActive"
		),
		"TutorialStep:",
		player:GetAttribute(
			"TutorialStep"
		)
	)

end


--==================================================
-- PLAYER ADDED
--==================================================

Players.PlayerAdded:Connect(
	function(player)

		task.spawn(
			SetupPlayer,
			player
		)

	end
)


--==================================================
-- EXISTING PLAYERS
--==================================================

-- This makes the script safe even if it starts after
-- a player has already joined the server.

for _, player in ipairs(
	Players:GetPlayers()
	) do

	task.spawn(
		SetupPlayer,
		player
	)

end


--==================================================
-- STARTED
--==================================================

print(
	"[TutorialServer] Started"
)
