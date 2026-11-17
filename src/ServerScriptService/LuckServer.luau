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
-- LUCK SERVICE
--==================================================

local LuckService =
	require(
		ServerScriptService
		:WaitForChild("LuckService")
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
-- LUCK REMOTES FOLDER
--==================================================

local luckRemotes =
	remotes:FindFirstChild(
		"Luck"
	)


if not luckRemotes then

	luckRemotes =
		Instance.new("Folder")


	luckRemotes.Name =
		"Luck"


	luckRemotes.Parent =
		remotes

end


--==================================================
-- GET LUCK STATE
--==================================================

local getLuckState =
	luckRemotes:FindFirstChild(
		"GetLuckState"
	)


if not getLuckState then

	getLuckState =
		Instance.new(
			"RemoteFunction"
		)


	getLuckState.Name =
		"GetLuckState"


	getLuckState.Parent =
		luckRemotes

end


--==================================================
-- PURCHASE LUCK
--==================================================

local purchaseLuck =
	luckRemotes:FindFirstChild(
		"PurchaseLuck"
	)


if not purchaseLuck then

	purchaseLuck =
		Instance.new(
			"RemoteFunction"
		)


	purchaseLuck.Name =
		"PurchaseLuck"


	purchaseLuck.Parent =
		luckRemotes

end


--==================================================
-- GET STATE HANDLER
--==================================================

getLuckState.OnServerInvoke =
	function(player)

		local state, errorMessage = LuckService.GetLuckState(player)


		if not state then

			return false, errorMessage

		end


		return true, state

	end


--==================================================
-- PURCHASE HANDLER
--==================================================

purchaseLuck.OnServerInvoke =
	function(
		player,
		plot,
		amount
	)

	return LuckService.PurchaseLuck(
		player,
		plot,
		amount
	)

end


--==================================================
-- CLEANUP
--==================================================

Players.PlayerRemoving:Connect(
	function(player)

		LuckService.CleanupPlayer(
			player
		)

	end
)
