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


local CurrencyService =
	require(
		script.Parent
		:WaitForChild("CurrencyService")
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild("Remotes")


local GetCurrencyState =
	Remotes:FindFirstChild(
		"GetCurrencyState"
	)


if not GetCurrencyState then

	GetCurrencyState =
		Instance.new("RemoteEvent")


	GetCurrencyState.Name =
		"GetCurrencyState"


	GetCurrencyState.Parent =
		Remotes

end


--==================================================
-- WAIT FOR PLAYER DATA
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
			0.25
		)

	end


	return nil

end


--==================================================
-- PLAYER JOINED
--==================================================

Players.PlayerAdded:Connect(
	function(player)

		task.spawn(
			function()

				local data =
					WaitForData(
						player
					)


				if not data then

					return

				end


				CurrencyService.SendCurrencyState(
					player
				)

			end
		)

	end
)


--==================================================
-- CLIENT REQUESTS CURRENT CURRENCY
--==================================================

GetCurrencyState.OnServerEvent:Connect(
	function(player)

		CurrencyService.SendCurrencyState(
			player
		)

	end
)
