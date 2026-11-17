--==================================================
-- SERVICES
--==================================================

local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)


--==================================================
-- GUI
--==================================================

local screenGui =
	script.Parent


local surfaceGui =
	screenGui:WaitForChild(
		"SurfaceGui"
	)


local mainFrame =
	surfaceGui:WaitForChild(
		"Frame"
	)


local scrollingFrame =
	mainFrame:WaitForChild(
		"ScrollingFrame"
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild(
		"Remotes"
	)


local TimePlayedRemotes =
	Remotes
	:WaitForChild(
		"TimePlayedLeaderboard"
	)


local GetLeaderboard =
	TimePlayedRemotes
	:WaitForChild(
		"GetLeaderboard"
	)


local LeaderboardUpdated =
	TimePlayedRemotes
	:WaitForChild(
		"LeaderboardUpdated"
	)


--==================================================
-- SETTINGS
--==================================================

local LEADERBOARD_SIZE =
	15


--==================================================
-- FORMAT PLAYTIME
--==================================================

local function FormatTime(
	totalSeconds
)

	totalSeconds =
		math.max(
			0,
			math.floor(
				totalSeconds or 0
			)
		)


	local days =
		math.floor(
			totalSeconds
			/ 86400
		)


	local hours =
		math.floor(
			(totalSeconds % 86400)
			/ 3600
		)


	local minutes =
		math.floor(
			(totalSeconds % 3600)
			/ 60
		)


	local seconds =
		totalSeconds
		% 60


	--==================================================
	-- DAYS
	--==================================================

	if days > 0 then

		return string.format(
			"%dd %dh %dm",
			days,
			hours,
			minutes
		)

	end


	--==================================================
	-- HOURS
	--==================================================

	if hours > 0 then

		return string.format(
			"%dh %dm %ds",
			hours,
			minutes,
			seconds
		)

	end


	--==================================================
	-- MINUTES
	--==================================================

	if minutes > 0 then

		return string.format(
			"%dm %ds",
			minutes,
			seconds
		)

	end


	--==================================================
	-- SECONDS
	--==================================================

	return string.format(
		"%ds",
		seconds
	)

end


--==================================================
-- GET INDEX FRAME
--==================================================

local function GetIndexFrame(
	index
)

	return scrollingFrame
		:FindFirstChild(
			tostring(index)
			.. "IndexFrame"
		)

end


--==================================================
-- CLEAR ONE ENTRY
--==================================================

local function ClearEntry(
	index
)

	local indexFrame =
		GetIndexFrame(
			index
		)


	if not indexFrame then

		warn(
			"[TimePlayedLeaderboardClient] Missing frame:",
			tostring(index)
				.. "IndexFrame"
		)


		return

	end


	local placementFrame =
		indexFrame
		:WaitForChild(
			"PlacementFrame"
		)


	local placementNumberText =
		placementFrame
		:WaitForChild(
			"PlacementNumberText"
		)


	local playerNameText =
		indexFrame
		:WaitForChild(
			"PlayerNameText"
		)


	local timePlayedText =
		indexFrame
		:WaitForChild(
			"TimePlayedText"
		)


	placementNumberText.Text =
		tostring(
			index
		)


	playerNameText.Text =
		"---"


	timePlayedText.Text =
		"---"


	indexFrame.LayoutOrder =
		index

end


--==================================================
-- UPDATE LEADERBOARD
--==================================================

local function UpdateLeaderboard(
	leaderboard
)

	if type(
		leaderboard
		) ~= "table" then

		return

	end


	for index = 1,
		LEADERBOARD_SIZE do

		local indexFrame =
			GetIndexFrame(
				index
			)


		if not indexFrame then

			warn(
				"[TimePlayedLeaderboardClient] Missing frame:",
				tostring(index)
					.. "IndexFrame"
			)


			continue

		end


		local placementFrame =
			indexFrame
			:WaitForChild(
				"PlacementFrame"
			)


		local placementNumberText =
			placementFrame
			:WaitForChild(
				"PlacementNumberText"
			)


		local playerNameText =
			indexFrame
			:WaitForChild(
				"PlayerNameText"
			)


		local timePlayedText =
			indexFrame
			:WaitForChild(
				"TimePlayedText"
			)


		--==================================================
		-- PLACEMENT
		--==================================================

		placementNumberText.Text =
			tostring(
				index
			)


		indexFrame.LayoutOrder =
			index


		--==================================================
		-- PLAYER ENTRY
		--==================================================

		local entry = leaderboard[index]


		if entry then

			playerNameText.Text =
				entry.PlayerName
				or "Unknown Player"


			timePlayedText.Text =
				FormatTime(
					entry.TimePlayed
				)

		else

			-- No player currently occupies
			-- this leaderboard position.

			playerNameText.Text =
				"---"


			timePlayedText.Text =
				"---"

		end

	end

end


--==================================================
-- CLEAR BOARD INITIALLY
--==================================================

for index = 1,
	LEADERBOARD_SIZE do

	ClearEntry(
		index
	)

end


--==================================================
-- INITIAL LEADERBOARD REQUEST
--==================================================

task.spawn(
	function()

		local success,
		leaderboard =
			pcall(
				function()

					return GetLeaderboard
					:InvokeServer()

				end
			)


		if not success then

			warn(
				"[TimePlayedLeaderboardClient] Failed to get leaderboard:",
				leaderboard
			)


			return

		end


		UpdateLeaderboard(
			leaderboard
		)

	end
)


--==================================================
-- LIVE LEADERBOARD UPDATES
--==================================================

LeaderboardUpdated.OnClientEvent:Connect(
	function(
		leaderboard
	)

		UpdateLeaderboard(
			leaderboard
		)

	end
)
