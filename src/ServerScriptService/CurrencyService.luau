local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


local LuckConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("LuckConfig")
	)

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


--==================================================
-- CURRENCY SERVICE
--==================================================

local CurrencyService = {}


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild("Remotes")


local CurrencyUpdate =
	Remotes:FindFirstChild(
		"CurrencyUpdate"
	)


if not CurrencyUpdate then

	CurrencyUpdate =
		Instance.new("RemoteEvent")


	CurrencyUpdate.Name =
		"CurrencyUpdate"


	CurrencyUpdate.Parent =
		Remotes

end


--==================================================
-- GET LUCK MULTIPLIER
--==================================================

function CurrencyService.GetLuckMultiplier(
	data
)

	if not data then

		return LuckConfig.StartingLuck

	end


	local luckLevel =
		data.LuckLevel
		or 0


	return LuckConfig.GetLuckMultiplier(
		luckLevel
	)

end


--==================================================
-- SEND CURRENT CURRENCY VALUES TO CLIENT
--==================================================

function CurrencyService.SendCurrencyState(
	player
)

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false

	end


	local dollars =
		data.Dollars
		or 0


	local luckMultiplier =
		CurrencyService.GetLuckMultiplier(
			data
		)


	CurrencyUpdate:FireClient(
		player,
		dollars,
		luckMultiplier
	)


	return true

end


--==================================================
-- ADD DOLLARS
--==================================================

function CurrencyService.AddDollars(
	player,
	amount
)

	if type(amount) ~= "number" then

		return false

	end


	if amount <= 0 then

		return false

	end


	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false

	end


	if type(data.Dollars) ~= "number" then

		data.Dollars =
			0

	end


	data.Dollars +=
		amount


	-- Immediately update the player's HUD.
	CurrencyService.SendCurrencyState(
		player
	)


	return true

end


--==================================================
-- SET DOLLARS
--==================================================

function CurrencyService.SetDollars(
	player,
	amount
)

	if type(amount) ~= "number" then

		return false

	end


	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false

	end


	data.Dollars =
		math.max(
			0,
			amount
		)


	CurrencyService.SendCurrencyState(
		player
	)


	return true

end


return CurrencyService
