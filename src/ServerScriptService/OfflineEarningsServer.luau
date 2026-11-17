--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


--==================================================
-- MODULES
--==================================================

local PlayerDataService =
	require(
		script.Parent
		:WaitForChild("PlayerDataService")
	)


local OfflineEarningsService =
	require(
		script.Parent
		:WaitForChild("OfflineEarningsService")
	)


local PlayerFeedbackService =
	require(
		script.Parent
		:WaitForChild("PlayerFeedbackService")
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild("Remotes")


--==================================================
-- GET OFFLINE EARNINGS
--==================================================

local GetOfflineEarnings =
	Remotes:FindFirstChild(
		"GetOfflineEarnings"
	)


if not GetOfflineEarnings then

	GetOfflineEarnings =
		Instance.new(
			"RemoteFunction"
		)


	GetOfflineEarnings.Name =
		"GetOfflineEarnings"


	GetOfflineEarnings.Parent =
		Remotes

end


--==================================================
-- CLAIM OFFLINE EARNINGS
--==================================================

local ClaimOfflineEarnings =
	Remotes:FindFirstChild(
		"ClaimOfflineEarnings"
	)


if not ClaimOfflineEarnings then

	ClaimOfflineEarnings =
		Instance.new(
			"RemoteFunction"
		)


	ClaimOfflineEarnings.Name =
		"ClaimOfflineEarnings"


	ClaimOfflineEarnings.Parent =
		Remotes

end


--==================================================
-- X2 CLAIM SUCCESS REMOTE
--==================================================

-- This is fired by the SERVER only after the
-- x2 Developer Product has successfully been
-- processed and the money has been granted.

local OfflineEarningsX2Claimed =
	Remotes:FindFirstChild(
		"OfflineEarningsX2Claimed"
	)


if not OfflineEarningsX2Claimed then

	OfflineEarningsX2Claimed =
		Instance.new(
			"RemoteEvent"
		)


	OfflineEarningsX2Claimed.Name =
		"OfflineEarningsX2Claimed"


	OfflineEarningsX2Claimed.Parent =
		Remotes

end


--==================================================
-- SESSION CALCULATION TRACKING
--==================================================

local calculatedThisSession =
	{}


--==================================================
-- WAIT FOR DATA
--==================================================

local function WaitForData(
	player
)

	while player.Parent do

		local data =
			PlayerDataService.GetData(
				player
			)


		if data then

			return data

		end


		task.wait(
			0.1
		)

	end


	return nil

end


--==================================================
-- CALCULATE ONCE THIS SESSION
--==================================================

local function EnsureCalculated(
	player
)

	if calculatedThisSession[
		player
		] then

		return OfflineEarningsService
			.GetPendingEarnings(
				player
			)

	end


	local data =
		WaitForData(
			player
		)


	if not data then

		return 0

	end


	local amount =
		OfflineEarningsService
		.CalculateForPlayer(
			player
		)


	calculatedThisSession[player] = true


	return amount

end


--==================================================
-- PLAYER JOINED
--==================================================

local function OnPlayerAdded(
	player
)

	task.spawn(
		function()

			EnsureCalculated(
				player
			)

		end
	)

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
-- CLIENT REQUESTS OFFLINE REWARD
--==================================================

GetOfflineEarnings.OnServerInvoke =
	function(player)

		return EnsureCalculated(
			player
		)

	end


--==================================================
-- CLIENT CLAIMS NORMAL REWARD
--==================================================

ClaimOfflineEarnings.OnServerInvoke =
	function(player)

		EnsureCalculated(
			player
		)


		local success, amount, reason = OfflineEarningsService.Claim(player)


		--==================================================
		-- PURCHASE SUCCESS SOUND
		--==================================================

		if success then

			PlayerFeedbackService.Send(
				player,
				"PumpkinMoneyCollect"
			)

		end


		return success, amount, reason

	end


--==================================================
-- PLAYER LEAVING
--==================================================

Players.PlayerRemoving:Connect(
	function(player)

		OfflineEarningsService
			.UpdateLastSeen(
				player
			)


		calculatedThisSession[player] = nil

	end
)
