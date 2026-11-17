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


local MostRollsRemotes =
	Remotes
	:WaitForChild(
		"MostRollsLeaderboard"
	)


local GetLeaderboard =
	MostRollsRemotes
	:WaitForChild(
		"GetLeaderboard"
	)


local LeaderboardUpdated =
	MostRollsRemotes
	:WaitForChild(
		"LeaderboardUpdated"
	)


--==================================================
-- SETTINGS
--==================================================

local LEADERBOARD_SIZE =
	15


--==================================================
-- FORMAT NUMBER
--==================================================

local function FormatNumber(
	number
)

	number =
		math.floor(
			number or 0
		)


	local formatted =
		tostring(
			number
		)


	while true do

		local newFormatted,
			count =
			string.gsub(
				formatted,
				"^(-?%d+)(%d%d%d)",
				"%1,%2"
			)


		formatted =
			newFormatted


		if count == 0 then

			break

		end

	end


	return formatted

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
				"[MostRollsLeaderboardClient] Missing:",
				tostring(index)
					.. "IndexFrame"
			)


			continue

		end


		--==================================================
		-- REFERENCES
		--==================================================

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


		local mostRollsText =
			indexFrame
			:WaitForChild(
				"MostRollsText"
			)


		--==================================================
		-- PLACEMENT NUMBER
		--==================================================

		placementNumberText.Text =
			tostring(
				index
			)


		indexFrame.LayoutOrder =
			index


		--==================================================
		-- LEADERBOARD ENTRY
		--==================================================

		local entry = leaderboard[index]


		if entry then

			playerNameText.Text =
				entry.PlayerName
				or "Unknown Player"


			mostRollsText.Text =
				FormatNumber(
					entry.Rolls
				)

		else

			playerNameText.Text =
				"---"


			mostRollsText.Text =
				"---"

		end

	end

end


--==================================================
-- CLEAR INITIAL BOARD
--==================================================

for index = 1,
	LEADERBOARD_SIZE do

	local indexFrame =
		GetIndexFrame(
			index
		)


	if indexFrame then

		local placementFrame =
			indexFrame
			:WaitForChild(
				"PlacementFrame"
			)


		placementFrame
			:WaitForChild(
				"PlacementNumberText"
			).Text =
			tostring(
				index
			)


		indexFrame
			:WaitForChild(
				"PlayerNameText"
			).Text =
			"---"


		indexFrame
			:WaitForChild(
				"MostRollsText"
			).Text =
			"---"


		indexFrame.LayoutOrder =
			index

	end

end


--==================================================
-- INITIAL REQUEST
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
				"[MostRollsLeaderboardClient] Failed to get leaderboard:",
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
-- LIVE UPDATES
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
