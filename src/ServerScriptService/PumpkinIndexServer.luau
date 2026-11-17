--==================================================
-- SERVICES
--==================================================

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


--==================================================
-- MODULES
--==================================================

local PumpkinIndexService =
	require(
		script.Parent
		:WaitForChild("PumpkinIndexService")
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild("Remotes")


local GetPumpkinIndex =
	Remotes:FindFirstChild(
		"GetPumpkinIndex"
	)


if not GetPumpkinIndex then

	GetPumpkinIndex =
		Instance.new(
			"RemoteFunction"
		)


	GetPumpkinIndex.Name =
		"GetPumpkinIndex"


	GetPumpkinIndex.Parent =
		Remotes

end


--==================================================
-- CLIENT REQUESTS INDEX
--==================================================

GetPumpkinIndex.OnServerInvoke =
	function(player)

		local index =
		PumpkinIndexService.GetIndex(
			player
		)


		-- Create a copy instead of returning the
		-- player's actual data table.

		local copy =
		{}


		for pumpkinId, unlocked in pairs(
			index
			) do

			if unlocked == true then

				copy[pumpkinId] =
				true

			end

		end


		return copy

	end
