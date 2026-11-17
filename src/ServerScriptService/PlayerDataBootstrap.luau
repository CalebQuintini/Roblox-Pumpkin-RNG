--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


--==================================================
-- MODULES
--==================================================

local PlayerDataService =
	require(
		script.Parent
		:WaitForChild("PlayerDataService")
	)


local PlayerRuntimeCleanup =
	require(
		script.Parent
		:WaitForChild("PlayerRuntimeCleanup")
	)


local PlotService =
	require(
		script.Parent
		:WaitForChild("PlotService")
	)


local PumpkinPlacementService =
	require(
		script.Parent
		:WaitForChild("PumpkinPlacementService")
	)


local PumpkinPurseAdapter =
	require(
		script.Parent
		:WaitForChild("PumpkinPurseAdapter")
	)


local PlayerToolService =
	require(
		script.Parent
		:WaitForChild("PlayerToolService")
	)

local GameAnalyticsService =
	require(
		script.Parent
		:WaitForChild("GameAnalyticsService")
	)


--==================================================
-- INITIALIZE PLOTS
--==================================================

PlotService.Initialize()


--==================================================
-- REFRESH PURSE
--==================================================

-- This helper recreates / updates the temporary
-- pumpkin proxy Tools that Purse displays.
--
-- The actual pumpkin ownership still comes from
-- PlayerData.Inventory.

local function RefreshPurse(player)

	local success,
		reason =
		PumpkinPurseAdapter
		.RefreshPlayer(
			player
		)


	if not success then

		warn(
			"Could not refresh Purse inventory for",
			player.Name,
			"Reason:",
			reason
		)

		return false

	end


	return true

end


--==================================================
-- PLAYER JOINED
--==================================================

local function PlayerAdded(player)

	--==================================================
	-- LOAD PLAYER DATA
	--==================================================

	local success,
		reason =
		PlayerDataService.LoadPlayer(
			player
		)


	-- If PlayerData failed...
	if not success then

		if reason
			== "ProfileAlreadyLoaded" then

			player:Kick(
				"Your data is currently active in another server. Please try again shortly."
			)

		else

			player:Kick(
				"Your player data could not be loaded safely. Please rejoin."
			)

		end


		return

	end
	
	--==================================================
	-- ANALYTICS - JOINED GAME
	--==================================================

	GameAnalyticsService.LogOnboardingStep(
		player,
		GameAnalyticsService.OnboardingSteps.JoinedGame
	)


	--==================================================
	-- INITIALIZE RUNTIME CLEANUP
	--==================================================

	PlayerRuntimeCleanup.InitializePlayer(
		player
	)


	--==================================================
	-- ASSIGN PLOT
	--==================================================

	local plot =
		PlotService.AssignPlot(
			player
		)


	-- If no plot is available...
	if not plot then

		-- Release their loaded save safely.
		PlayerDataService.ReleasePlayer(
			player
		)


		-- Remove them from this server.
		player:Kick(
			"No pumpkin patch is currently available. Please try another server."
		)


		return

	end


	--==================================================
	-- REGISTER PLOT CLEANUP
	--==================================================

	PlayerRuntimeCleanup.AddCleanupCallback(
		player,

		function()

			PlotService.ReleasePlot(
				player
			)

		end
	)


	--==================================================
	-- GET PLAYER DATA
	--==================================================

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		warn(
			"PlayerData was expected to be loaded but could not be retrieved for",
			player.Name
		)

		return

	end


	--==================================================
	-- CREATE FIXED PLAYER TOOLS FIRST
	--==================================================

	-- Purse should see these before the pumpkin
	-- proxy Tools.
	--
	-- PlayerToolService currently gives the Hammer.
	--
	-- Baseball Bat R15 lives in StarterPack and is
	-- automatically handled by Roblox.

	PlayerToolService.GiveDefaultTools(
		player
	)


	--==================================================
	-- RESTORE PURSE INVENTORY
	--==================================================

	-- PlayerData has now loaded.
	--
	-- Recreate one temporary proxy Tool for each
	-- pumpkin type the player currently owns.
	--
	-- Example:
	--
	-- Saved Inventory:
	--
	-- CarvedPumpkin x5
	-- NormalPumpkin x2
	--
	-- becomes temporary runtime Tools:
	--
	-- Backpack
	-- ├── Carved Pumpkin
	-- │   Quantity = 5
	-- │
	-- └── Normal Pumpkin
	--     Quantity = 2
	--
	-- Purse detects these Tools automatically.

	RefreshPurse(
		player
	)


	--==================================================
	-- CHARACTER SPAWNING
	--==================================================

	-- Whenever the player's character respawns...

	local characterConnection =
		player.CharacterAdded:Connect(
			function(character)

				-- Wait one frame so Roblox has created
				-- the new Backpack / Character state.
				task.wait()


				--==================================================
				-- RESTORE FIXED PLAYER TOOLS
				--==================================================

				-- Hammer does NOT live in StarterPack.
				--
				-- Because of that, Roblox will not
				-- automatically recreate it after a
				-- respawn.
				--
				-- GiveDefaultTools is safe to call
				-- repeatedly because PlayerToolService
				-- first checks the Backpack and Character
				-- before cloning another Hammer.

				PlayerToolService.GiveDefaultTools(
					player
				)


				--==================================================
				-- TELEPORT TO ASSIGNED PLOT
				--==================================================

				-- Ensure the character appears at
				-- their assigned pumpkin patch.

				PlotService.TeleportPlayerToPlot(
					player,
					character
				)


				--==================================================
				-- REFRESH PURSE AFTER RESPAWN
				--==================================================

				-- Equipping Tools moves them between:
				--
				-- Player.Backpack
				-- and
				-- Player.Character
				--
				-- When the character respawns, refresh
				-- the pumpkin proxy Tools to make sure
				-- every owned pumpkin type still has
				-- its Purse representation.

				task.defer(
					function()

						RefreshPurse(
							player
						)

					end
				)

			end
		)


	-- Register this event connection so it is
	-- disconnected when the player leaves.

	PlayerRuntimeCleanup.TrackConnection(
		player,
		characterConnection
	)


	--==================================================
	-- HANDLE ALREADY-SPAWNED CHARACTER
	--==================================================

	-- Sometimes the character may spawn before
	-- PlayerData finishes loading.

	if player.Character then

		--==================================================
		-- MAKE SURE HAMMER EXISTS
		--==================================================

		-- This protects against the character already
		-- existing before CharacterAdded was connected.

		PlayerToolService.GiveDefaultTools(
			player
		)


		--==================================================
		-- TELEPORT TO PLOT
		--==================================================

		PlotService.TeleportPlayerToPlot(
			player,
			player.Character
		)


		--==================================================
		-- REFRESH PURSE
		--==================================================

		-- Also make sure Purse is synchronized
		-- with this already-existing character.

		task.defer(
			function()

				RefreshPurse(
					player
				)

			end
		)

	end


	--==================================================
	-- RESTORE SAVED PLACED PUMPKINS
	--==================================================

	-- Recreate every physical pumpkin that the
	-- player's save says should be on their plot.

	PumpkinPlacementService.RestoreSavedPumpkins(
		player,
		data
	)


	--==================================================
	-- DEBUG OUTPUT
	--==================================================

	print(
		player.Name,
		"Dollars:",
		data.Dollars
	)


	print(
		player.Name,
		"Luck Level:",
		data.LuckLevel
	)


	print(
		player.Name,
		"Inventory pumpkins:",
		#data.Inventory
	)


	print(
		player.Name,
		"Plot:",
		plot:GetAttribute(
			"PlotId"
		)
	)

end


--==================================================
-- PLAYER LEAVING
--==================================================

local function PlayerRemoving(player)

	-- First finalize and remove all temporary
	-- server/runtime state.

	PlayerRuntimeCleanup.CleanupPlayer(
		player
	)


	-- Then save the player's final persistent data.

	PlayerDataService.ReleasePlayer(
		player
	)

end


--==================================================
-- CONNECTIONS
--==================================================

Players.PlayerAdded:Connect(
	PlayerAdded
)


Players.PlayerRemoving:Connect(
	PlayerRemoving
)


--==================================================
-- HANDLE EXISTING PLAYERS
--==================================================

for _, player in ipairs(
	Players:GetPlayers()
	) do

	task.spawn(
		PlayerAdded,
		player
	)

end


--==================================================
-- SERVER SHUTDOWN
--==================================================

game:BindToClose(
	function()

		local remaining =
			0


		for _, player in ipairs(
			Players:GetPlayers()
			) do

			if PlayerDataService.IsLoaded(
				player
				) then

				remaining += 1


				task.spawn(
					function()

						-- Finalize runtime systems first.

						PlayerRuntimeCleanup.CleanupPlayer(
							player
						)


						-- Save persistent data afterward.

						PlayerDataService.ReleasePlayer(
							player
						)


						remaining -= 1

					end
				)

			end

		end


		local startTime =
			os.clock()


		while remaining > 0
			and os.clock() - startTime < 25 do

			task.wait(
				0.1
			)

		end

	end
)
