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


local PumpkinIncomeService =
	require(
		script.Parent
		:WaitForChild("PumpkinIncomeService")
	)


--==================================================
-- SERVICE
--==================================================

local AutoCollectService = {}


--==================================================
-- PRODUCT ID
--==================================================

AutoCollectService.PRODUCT_ID =
	3718536179


--==================================================
-- DOES PLAYER OWN AUTO COLLECT?
--==================================================

function AutoCollectService.OwnsAutoCollect(
	player
)

	if not player then

		return false

	end


	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false

	end


	return data.AutoCollectOwned
		== true

end


--==================================================
-- GRANT AUTO COLLECT
--==================================================

function AutoCollectService.GrantAutoCollect(
	player
)

	if not player then

		return false,
			"InvalidPlayer"

	end


	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false,
			"DataNotLoaded"

	end


	--==================================================
	-- ALREADY OWNED
	--==================================================

	if data.AutoCollectOwned
		== true then

		return true,
			"AlreadyOwned"

	end


	--==================================================
	-- PERMANENTLY UNLOCK
	--==================================================

	data.AutoCollectOwned =
		true


	return true,
		"AutoCollectGranted"

end


--==================================================
-- GET TOTAL MONEY WAITING
--==================================================

function AutoCollectService.GetStoredMoney(
	player
)

	if not player then

		return 0

	end


	return PumpkinIncomeService
		.GetTotalStoredMoney(
			player
		)

end


--==================================================
-- COLLECT ALL MONEY
--==================================================

function AutoCollectService.Collect(
	player
)

	if not player then

		return false,
			0,
			"InvalidPlayer"

	end


	--==================================================
	-- MUST OWN AUTO COLLECT
	--==================================================

	if not AutoCollectService
		.OwnsAutoCollect(
			player
		) then

		return false,
			0,
			"NotOwned"

	end


	-- PumpkinIncomeService.CollectAll() handles:
	--
	-- * adding every pumpkin's StoredMoney together
	-- * resetting every StoredMoney to 0
	-- * paying the player
	-- * updating pumpkin displays
	-- * playing PumpkinMoneyCollect

	return PumpkinIncomeService
		.CollectAll(
			player
		)

end


return AutoCollectService
