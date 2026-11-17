--==================================================
-- PLAYER RUNTIME CLEANUP SERVICE
--==================================================

-- This service keeps track of temporary objects,
-- connections, and cleanup functions that belong
-- to each player while they are inside the server.
--
-- None of the information stored here is permanent
-- PlayerData.
--
-- When the player leaves, everything registered
-- here can be cleaned up safely.


-- Create the ModuleScript table that other scripts
-- will require and use.
local PlayerRuntimeCleanup = {}


--==================================================
-- RUNTIME DATA
--==================================================

-- This table stores temporary runtime information
-- for every player currently being tracked.
--
-- Example:
--
-- PlayerRuntime[player] = {
--
--     Instances = {},
--     Connections = {},
--     CleanupCallbacks = {},
--
-- }
--
-- The Player object itself is used as the key.
local PlayerRuntime = {}


--==================================================
-- CREATE PLAYER RUNTIME ENTRY
--==================================================

local function CreateRuntimeEntry(player)

	-- Check whether this player already has
	-- a runtime entry.
	if PlayerRuntime[player] then

		-- If they already have one, return it
		-- instead of creating another.
		return PlayerRuntime[player]

	end


	-- Create a new table that will hold all
	-- temporary runtime resources for this player.
	local runtimeEntry = {

		-- Instances can include things such as:
		--
		-- pumpkin models
		-- income collectors
		-- temporary folders
		-- temporary effects
		Instances = {},


		-- Connections contains RBXScriptConnections
		-- created for this player.
		--
		-- Examples:
		--
		-- Touched connections
		-- ProximityPrompt connections
		-- attribute change connections
		-- plot events
		Connections = {},


		-- CleanupCallbacks contains functions
		-- that another system wants us to run
		-- when this player leaves.
		--
		-- For example:
		--
		-- Release their plot
		-- Remove lock state
		-- Cancel an active theft
		CleanupCallbacks = {},
	}


	-- Save this runtime entry under the player.
	PlayerRuntime[player] = runtimeEntry


	-- Return the newly created entry.
	return runtimeEntry

end


--==================================================
-- INITIALIZE PLAYER
--==================================================

function PlayerRuntimeCleanup.InitializePlayer(player)

	-- Make sure this player has a runtime entry.
	CreateRuntimeEntry(player)

end


--==================================================
-- TRACK TEMPORARY INSTANCE
--==================================================

function PlayerRuntimeCleanup.TrackInstance(
	player,
	instance
)

	-- Make sure the player has a runtime entry.
	local runtimeEntry =
		CreateRuntimeEntry(player)


	-- Add this Instance to the player's
	-- temporary instance list.
	table.insert(
		runtimeEntry.Instances,
		instance
	)


	-- Return the Instance.
	--
	-- This is convenient because another system
	-- can do:
	--
	-- local pumpkin =
	--     PlayerRuntimeCleanup.TrackInstance(
	--         player,
	--         pumpkinModel
	--     )
	return instance

end


--==================================================
-- TRACK CONNECTION
--==================================================

function PlayerRuntimeCleanup.TrackConnection(
	player,
	connection
)

	-- Make sure the player has a runtime entry.
	local runtimeEntry =
		CreateRuntimeEntry(player)


	-- Store this RBXScriptConnection.
	table.insert(
		runtimeEntry.Connections,
		connection
	)


	-- Return the connection for convenience.
	return connection

end


--==================================================
-- ADD CUSTOM CLEANUP FUNCTION
--==================================================

function PlayerRuntimeCleanup.AddCleanupCallback(
	player,
	callback
)

	-- Make sure the player has a runtime entry.
	local runtimeEntry =
		CreateRuntimeEntry(player)


	-- Add the supplied function to the list
	-- of things that must happen when the
	-- player leaves.
	table.insert(
		runtimeEntry.CleanupCallbacks,
		callback
	)

end


--==================================================
-- CLEAN UP PLAYER
--==================================================

function PlayerRuntimeCleanup.CleanupPlayer(player)

	-- Get the runtime information belonging
	-- to this player.
	local runtimeEntry =
		PlayerRuntime[player]


	-- If we were not tracking this player,
	-- there is nothing to clean up.
	if not runtimeEntry then
		return
	end


	--==================================================
	-- RUN CUSTOM CLEANUP CALLBACKS
	--==================================================

	-- Go through every cleanup function that
	-- other systems registered.
	for _, callback in ipairs(
		runtimeEntry.CleanupCallbacks
		) do

		-- Use pcall so one broken cleanup function
		-- does not prevent all other cleanup from
		-- happening.
		local success, errorMessage =
			pcall(callback)


		-- If the cleanup function produced an error,
		-- print a warning so we can find the problem.
		if not success then

			warn(
				"Player cleanup callback failed for",
				player.Name,
				errorMessage
			)

		end

	end


	--==================================================
	-- DISCONNECT EVENTS
	--==================================================

	-- Go through every connection that belongs
	-- to this player.
	for _, connection in ipairs(
		runtimeEntry.Connections
		) do

		-- Make sure the connection still exists
		-- and hasn't already been disconnected.
		if connection.Connected then

			-- Disconnect the event.
			connection:Disconnect()

		end

	end


	--==================================================
	-- DESTROY TEMPORARY INSTANCES
	--==================================================

	-- Go through all temporary Instances that
	-- belong to this player.
	for _, instance in ipairs(
		runtimeEntry.Instances
		) do

		-- Check whether the Instance still exists.
		--
		-- Parent being nil usually means it was
		-- already destroyed or removed.
		if instance
			and instance.Parent then

			-- Destroy the Instance completely.
			instance:Destroy()

		end

	end


	--==================================================
	-- REMOVE RUNTIME ENTRY
	--==================================================

	-- We no longer need this player's temporary
	-- runtime information.
	PlayerRuntime[player] = nil

end


--==================================================
-- RETURN MODULE
--==================================================

return PlayerRuntimeCleanup
