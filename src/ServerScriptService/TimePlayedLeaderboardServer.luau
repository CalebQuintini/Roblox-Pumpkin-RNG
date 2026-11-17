--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService(
		"Players"
	)


local DataStoreService =
	game:GetService(
		"DataStoreService"
	)


local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)


--==================================================
-- ORDERED DATASTORE
--==================================================

-- This OrderedDataStore stores the player's
-- TOTAL accumulated playtime in seconds.
--
-- Because it is an OrderedDataStore, Roblox can
-- automatically sort players from highest to lowest.

local TimePlayedStore =
	DataStoreService:GetOrderedDataStore(
		"PumpkinRNG_TimePlayed_v1"
	)


--==================================================
-- SETTINGS
--==================================================

-- Save accumulated playtime every 60 seconds.
--
-- We do NOT want to save every second because
-- that would produce far too many DataStore requests.

local SAVE_INTERVAL =
	60


-- Refresh the global leaderboard every 60 seconds.

local LEADERBOARD_REFRESH_INTERVAL =
	60


-- Number of players shown on the board.

local LEADERBOARD_SIZE =
	15


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage:FindFirstChild(
		"Remotes"
	)


if not Remotes then

	Remotes =
		Instance.new(
			"Folder"
		)


	Remotes.Name =
		"Remotes"


	Remotes.Parent =
		ReplicatedStorage

end


--==================================================
-- TIME PLAYED REMOTES FOLDER
--==================================================

local TimePlayedRemotes =
	Remotes:FindFirstChild(
		"TimePlayedLeaderboard"
	)


if not TimePlayedRemotes then

	TimePlayedRemotes =
		Instance.new(
			"Folder"
		)


	TimePlayedRemotes.Name =
		"TimePlayedLeaderboard"


	TimePlayedRemotes.Parent =
		Remotes

end


--==================================================
-- GET LEADERBOARD REMOTE FUNCTION
--==================================================

local GetLeaderboard =
	TimePlayedRemotes:FindFirstChild(
		"GetLeaderboard"
	)


if not GetLeaderboard then

	GetLeaderboard =
		Instance.new(
			"RemoteFunction"
		)


	GetLeaderboard.Name =
		"GetLeaderboard"


	GetLeaderboard.Parent =
		TimePlayedRemotes

end


--==================================================
-- LEADERBOARD UPDATED REMOTE EVENT
--==================================================

local LeaderboardUpdated =
	TimePlayedRemotes:FindFirstChild(
		"LeaderboardUpdated"
	)


if not LeaderboardUpdated then

	LeaderboardUpdated =
		Instance.new(
			"RemoteEvent"
		)


	LeaderboardUpdated.Name =
		"LeaderboardUpdated"


	LeaderboardUpdated.Parent =
		TimePlayedRemotes

end


--==================================================
-- PLAYER SESSION DATA
--==================================================

-- [player] = {
--
--     LastCheckpoint = os.time()
--
-- }
--
-- Every time we save, we calculate how many seconds
-- have passed since LastCheckpoint and ADD those
-- seconds to the OrderedDataStore.

local PlayerSessions =
	{}


--==================================================
-- USERNAME CACHE
--==================================================

-- Resolving a UserId into a Roblox username requires
-- a Roblox request.
--
-- Cache names so we do not repeatedly request them.

local UsernameCache =
	{}


--==================================================
-- CURRENT LEADERBOARD
--==================================================

local CurrentLeaderboard =
	{}


--==================================================
-- GET PLAYER KEY
--==================================================

local function GetPlayerKey(
	player
)

	return tostring(
		player.UserId
	)

end


--==================================================
-- FIND ACTIVE PLAYER BY USER ID
--==================================================

local function FindActivePlayer(
	userId
)

	for _, player in ipairs(
		Players:GetPlayers()
		) do

		if player.UserId
			== userId then

			return player

		end

	end


	return nil

end


--==================================================
-- GET USERNAME
--==================================================

local function GetUsername(
	userId
)

	--==================================================
	-- CACHE
	--==================================================

	if UsernameCache[
		userId
		] then

		return UsernameCache[userId]

	end


	--==================================================
	-- CURRENT SERVER PLAYER
	--==================================================

	local activePlayer =
		FindActivePlayer(
			userId
		)


	if activePlayer then

		UsernameCache[userId] = activePlayer.Name


		return activePlayer.Name

	end


	--==================================================
	-- ROBLOX USERNAME LOOKUP
	--==================================================

	local success,
		result =
		pcall(
			function()

				return Players
				:GetNameFromUserIdAsync(
					userId
				)

			end
		)


	if success then

		UsernameCache[userId] = result


		return result

	end


	-- This can happen with Studio test players
	-- because Studio can use negative UserIds.

	return "Unknown Player"

end


--==================================================
-- SAVE PLAYER TIME
--==================================================

local function SavePlayerTime(
	player
)

	local session = PlayerSessions[player]


	if not session then

		return false

	end


	local currentTime =
		os.time()


	local secondsToAdd =
		currentTime
	- session.LastCheckpoint


	-- Nothing new to save.

	if secondsToAdd <= 0 then

		return true

	end


	local key =
		GetPlayerKey(
			player
		)


	--==================================================
	-- ADD TIME TO EXISTING TOTAL
	--==================================================

	local success,
		result =
		pcall(
			function()

				return TimePlayedStore
				:UpdateAsync(

					key,

					function(
						currentValue
					)

						currentValue = tonumber(
							currentValue
						)
						or 0


						return currentValue
						+ secondsToAdd

					end
				)

			end
		)


	if not success then

		warn(
			"[TimePlayedLeaderboard] Failed to save time for",
			player.Name,
			result
		)


		-- IMPORTANT:
		--
		-- Do NOT update LastCheckpoint when the
		-- DataStore save fails.
		--
		-- That means the unsaved time will be
		-- attempted again on the next save.

		return false

	end


	--==================================================
	-- SAVE SUCCESSFUL
	--==================================================

	session.LastCheckpoint =
		currentTime


	return true

end


--==================================================
-- BUILD GLOBAL LEADERBOARD
--==================================================

local function BuildLeaderboard()

	local success,
		pages =
		pcall(
			function()

				-- false = descending
				--
				-- Highest playtime comes first.

				return TimePlayedStore
				:GetSortedAsync(
					false,
					LEADERBOARD_SIZE
				)

			end
		)


	if not success then

		warn(
			"[TimePlayedLeaderboard] Failed to retrieve leaderboard:",
			pages
		)


		return CurrentLeaderboard

	end


	local page =
		pages:GetCurrentPage()


	local leaderboard =
		{}


	for placement,
		entry in ipairs(
			page
		) do

		local userId =
			tonumber(
				entry.key
			)


		local timePlayed =
			tonumber(
				entry.value
			)
			or 0


		local playerName =
			"Unknown Player"


		if userId then

			playerName =
				GetUsername(
					userId
				)

		end


		table.insert(
			leaderboard,

			{
				Placement =
					placement,

				UserId =
					userId,

				PlayerName =
					playerName,

				TimePlayed =
					timePlayed,
			}
		)

	end


	CurrentLeaderboard =
		leaderboard


	return leaderboard

end


--==================================================
-- BROADCAST LEADERBOARD
--==================================================

local function RefreshLeaderboard()

	local leaderboard =
		BuildLeaderboard()


	LeaderboardUpdated:FireAllClients(
		leaderboard
	)

end


--==================================================
-- REMOTE FUNCTION
--==================================================

GetLeaderboard.OnServerInvoke =
	function()

		return CurrentLeaderboard

	end


--==================================================
-- PLAYER JOINED
--==================================================

local function OnPlayerAdded(
	player
)

	PlayerSessions[player] =
		{
			LastCheckpoint =
			os.time(),
		}


	-- Cache their current Roblox username.

	UsernameCache[player.UserId] =player.Name

end


Players.PlayerAdded:Connect(
	OnPlayerAdded
)


-- Support players already connected if this
-- script starts after PlayerAdded fires.

for _, player in ipairs(
	Players:GetPlayers()
	) do

	OnPlayerAdded(
		player
	)

end


--==================================================
-- PLAYER LEAVING
--==================================================

Players.PlayerRemoving:Connect(
	function(player)

		-- Save any remaining unsaved seconds.

		SavePlayerTime(
			player
		)


		PlayerSessions[player] = nil

	end
)


--==================================================
-- PERIODIC PLAYER SAVE
--==================================================

task.spawn(
	function()

		while true do

			task.wait(
				SAVE_INTERVAL
			)


			for _, player in ipairs(
				Players:GetPlayers()
				) do

				SavePlayerTime(
					player
				)

			end

		end

	end
)


--==================================================
-- PERIODIC LEADERBOARD REFRESH
--==================================================

task.spawn(
	function()

		-- Give the server a moment to initialize.

		task.wait(
			2
		)


		RefreshLeaderboard()


		while true do

			task.wait(
				LEADERBOARD_REFRESH_INTERVAL
			)


			--==================================================
			-- SAVE CURRENT PLAYERS FIRST
			--==================================================

			-- This means the leaderboard will include
			-- their most recent playtime before sorting.

			for _, player in ipairs(
				Players:GetPlayers()
				) do

				SavePlayerTime(
					player
				)

			end


			RefreshLeaderboard()

		end

	end
)


--==================================================
-- SERVER SHUTDOWN
--==================================================

game:BindToClose(
	function()

		for _, player in ipairs(
			Players:GetPlayers()
			) do

			SavePlayerTime(
				player
			)

		end

	end
)


print(
	"[TimePlayedLeaderboard] Started"
)
