--==================================================
-- SERVICES
--==================================================

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


local PumpkinConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("PumpkinConfig")
	)


--==================================================
-- SERVICE
--==================================================

local PumpkinIndexService = {}


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild("Remotes")


local PumpkinIndexUpdated =
	Remotes:FindFirstChild(
		"PumpkinIndexUpdated"
	)


if not PumpkinIndexUpdated then

	PumpkinIndexUpdated =
		Instance.new(
			"RemoteEvent"
		)


	PumpkinIndexUpdated.Name =
		"PumpkinIndexUpdated"


	PumpkinIndexUpdated.Parent =
		Remotes

end


--==================================================
-- GET INDEX TABLE
--==================================================

function PumpkinIndexService.GetIndex(
	player
)

	if not player then

		return {}

	end


	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return {}

	end


	-- Support older save files.

	if type(data.PumpkinIndex)
		~= "table" then

		data.PumpkinIndex =
			{}

	end


	return data.PumpkinIndex

end


--==================================================
-- IS PUMPKIN UNLOCKED?
--==================================================

function PumpkinIndexService.IsUnlocked(
	player,
	pumpkinId
)

	if not PumpkinConfig.IsValidPumpkin(
		pumpkinId
		) then

		return false

	end


	local index =
		PumpkinIndexService.GetIndex(
			player
		)


	return index[pumpkinId]
		== true

end


--==================================================
-- UNLOCK PUMPKIN
--==================================================

function PumpkinIndexService.Unlock(
	player,
	pumpkinId
)

	if not player then

		return false,
			"InvalidPlayer"

	end


	if not PumpkinConfig.IsValidPumpkin(
		pumpkinId
		) then

		return false,
			"InvalidPumpkin"

	end


	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false,
			"DataNotLoaded"

	end


	if type(data.PumpkinIndex)
		~= "table" then

		data.PumpkinIndex =
			{}

	end


	--==================================================
	-- ALREADY UNLOCKED
	--==================================================

	if data.PumpkinIndex[
		pumpkinId
		] == true then

		return true,
			"AlreadyUnlocked"

	end


	--==================================================
	-- PERMANENTLY UNLOCK
	--==================================================

	data.PumpkinIndex[
	pumpkinId
	] =
		true


	--==================================================
	-- UPDATE CLIENT
	--==================================================

	PumpkinIndexUpdated:FireClient(
		player,
		pumpkinId
	)


	return true,
		"Unlocked"

end


return PumpkinIndexService
