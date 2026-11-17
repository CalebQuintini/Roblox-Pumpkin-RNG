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


local ServerScriptService =
	game:GetService(
		"ServerScriptService"
	)


--==================================================
-- ORDERED DATASTORE
--==================================================

local MostRollsStore =
	DataStoreService:GetOrderedDataStore(
		"PumpkinRNG_MostRolls_v1"
	)


--==================================================
-- SETTINGS
--==================================================

local LEADERBOARD_SIZE =
	15


local SAVE_INTERVAL =
	60


local REFRESH_INTERVAL =
	60


--==================================================
-- BINDABLE EVENT
--==================================================

-- PumpkinRollService fires this whenever
-- the server successfully creates a new roll.

local RecordPumpkinRoll =
	ServerScriptService:FindFirstChild(
		"RecordPumpkinRoll"
	)


if not RecordPumpkinRoll then

	RecordPumpkinRoll =
		Instance.new(
			"BindableEvent"
		)


	RecordPumpkinRoll.Name =
		"RecordPumpkinRoll"


	RecordPumpkinRoll.Parent =
		ServerScriptService

end


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


local MostRollsRemotes =
	Remotes:FindFirstChild(
		"MostRollsLeaderboard"
	)


if not MostRollsRemotes then

	MostRollsRemotes =
		Instance.new(
			"Folder"
		)


	MostRollsRemotes.Name =
		"MostRollsLeaderboard"


	MostRollsRemotes.Parent =
		Remotes

end


--==================================================
-- GET LEADERBOARD REMOTE
--==================================================

local GetLeaderboard =
	MostRollsRemotes:FindFirstChild(
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
		MostRollsRemotes

end


--==================================================
-- LEADERBOARD UPDATED REMOTE
--==================================================

local LeaderboardUpdated =
	MostRollsRemotes:FindFirstChild(
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
		MostRollsRemotes

end


--==================================================
-- PENDING ROLLS
--==================================================

-- We do NOT save to DataStore every time
-- the player presses Roll.
--
-- Instead we accumulate their rolls here
-- and periodically add them to the
-- OrderedDataStore.
--
-- [player] = number

local PendingRolls =
	{}


--==================================================
-- USERNAME CACHE
--==================================================

local UsernameCache =
	{}


--==================================================
-- CURRENT LEADERBOARD
--==================================================

local CurrentLeaderboard =
	{}


--==================================================
-- FIND ACTIVE PLAYER
--==================================================

local function FindActivePlayerByUserId(
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

	if UsernameCache[
		userId
		] then

		return UsernameCache[userId]

	end


	--==================================================
	-- CURRENT SERVER
	--==================================================

	local activePlayer =
		FindActivePlayerByUserId(
			userId
		)


	if activePlayer then

		UsernameCache[userId] = activePlayer.Name


		return activePlayer.Name

	end


	--==================================================
	-- ROBLOX LOOKUP
	--==================================================

	local success,
		name =
		pcall(
			function()

				return Players
				:GetNameFromUserIdAsync(
					userId
				)

			end
		)


	if success then

		UsernameCache[userId] = name


		return name

	end


	return "Unknown Player"

end


--==================================================
-- RECORD ROLL
--==================================================

RecordPumpkinRoll.Event:Connect(
	function(player)

		if not player
			or not player:IsA(
				"Player"
			) then

			return

		end


		PendingRolls[player] = (PendingRolls[player] or 0) + 1

	end
)


--==================================================
-- SAVE PLAYER PENDING ROLLS
--==================================================

local function SavePlayerRolls(
	player
)

	local amount =
		PendingRolls[player]
		or 0


	if amount <= 0 then

		return true

	end


	local key =
		tostring(
			player.UserId
		)


	local success,
		result =
		pcall(
			function()

				return MostRollsStore
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
						+ amount

					end
				)

			end
		)


	if not success then

		warn(
			"[MostRollsLeaderboard] Failed to save rolls for",
			player.Name,
			result
		)


		return false

	end


	-- Only remove rolls after a successful save.

	PendingRolls[player
	] =
		math.max(
			0,
			(PendingRolls[player] or 0)
			- amount
		)


	return true

end


--==================================================
-- BUILD LEADERBOARD
--==================================================

local function BuildLeaderboard()

	local success,
		pages =
		pcall(
			function()

				return MostRollsStore
				:GetSortedAsync(
					false,
					LEADERBOARD_SIZE
				)

			end
		)


	if not success then

		warn(
			"[MostRollsLeaderboard] Failed to retrieve leaderboard:",
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


		local rolls =
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

				Rolls =
					rolls,
			}
		)

	end


	CurrentLeaderboard =
		leaderboard


	return leaderboard

end


--==================================================
-- REFRESH LEADERBOARD
--==================================================

local function RefreshLeaderboard()

	local leaderboard =
		BuildLeaderboard()


	LeaderboardUpdated:FireAllClients(
		leaderboard
	)

end


--==================================================
-- CLIENT REQUEST
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

	PendingRolls[player] = 0


	UsernameCache[player.UserId] = player.Name

end


Players.PlayerAdded:Connect(
	OnPlayerAdded
)


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

		SavePlayerRolls(
			player
		)


		PendingRolls[player] = nil

	end
)


--==================================================
-- PERIODIC SAVE
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

				SavePlayerRolls(
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

		task.wait(
			2
		)


		RefreshLeaderboard()


		while true do

			task.wait(
				REFRESH_INTERVAL
			)


			-- Save current pending rolls first.

			for _, player in ipairs(
				Players:GetPlayers()
				) do

				SavePlayerRolls(
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

			SavePlayerRolls(
				player
			)

		end

	end
)


print(
	"[MostRollsLeaderboard] Started"
)
