--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


local ServerScriptService =
	game:GetService("ServerScriptService")


--==================================================
-- SERVICE
--==================================================

local PumpkinRollService =
	require(
		ServerScriptService:WaitForChild(
			"PumpkinRollService"
		)
	)


--==================================================
-- REMOTES FOLDER
--==================================================

local remotes =
	ReplicatedStorage:FindFirstChild(
		"Remotes"
	)


if not remotes then

	remotes =
		Instance.new("Folder")


	remotes.Name =
		"Remotes"


	remotes.Parent =
		ReplicatedStorage

end


--==================================================
-- PUMPKIN ROLL REMOTES
--==================================================

local rollRemotes =
	remotes:FindFirstChild(
		"PumpkinRoll"
	)


if not rollRemotes then

	rollRemotes =
		Instance.new("Folder")


	rollRemotes.Name =
		"PumpkinRoll"


	rollRemotes.Parent =
		remotes

end


--==================================================
-- REQUEST ROLL
--==================================================

local requestRoll =
	rollRemotes:FindFirstChild(
		"RequestRoll"
	)


if not requestRoll then

	requestRoll =
		Instance.new(
			"RemoteFunction"
		)


	requestRoll.Name =
		"RequestRoll"


	requestRoll.Parent =
		rollRemotes

end


--==================================================
-- BUY OFFER
--==================================================

local buyOffer =
	rollRemotes:FindFirstChild(
		"BuyOffer"
	)


if not buyOffer then

	buyOffer =
		Instance.new(
			"RemoteFunction"
		)


	buyOffer.Name =
		"BuyOffer"


	buyOffer.Parent =
		rollRemotes

end


--==================================================
-- REQUEST ROLL HANDLER
--==================================================

requestRoll.OnServerInvoke =
	function(player)

		return PumpkinRollService
		.RequestRoll(
			player
		)

	end


--==================================================
-- BUY HANDLER
--==================================================

buyOffer.OnServerInvoke =
	function(
		player,
		offerId
	)

	return PumpkinRollService
		.BuyOffer(
			player,
			offerId
		)

end


--==================================================
-- CLEANUP
--==================================================

Players.PlayerRemoving:Connect(
	function(player)

		PumpkinRollService
			.CleanupPlayer(
				player
			)

	end
)
