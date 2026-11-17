--==================================================
-- SERVICES
--==================================================

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


local ServerScriptService =
	game:GetService("ServerScriptService")


--==================================================
-- CONFIG
--==================================================

local LuckConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("LuckConfig")
	)


--==================================================
-- SERVER MODULES
--==================================================

local PlayerDataService =
	require(
		ServerScriptService
		:WaitForChild("PlayerDataService")
	)


local CurrencyService =
	require(
		ServerScriptService
		:WaitForChild("CurrencyService")
	)


local PlotService =
	require(
		ServerScriptService
		:WaitForChild("PlotService")
	)

local PlayerFeedbackService =
	require(
		ServerScriptService
		:WaitForChild("PlayerFeedbackService")
	)


--==================================================
-- MODULE
--==================================================

local LuckService = {}


--==================================================
-- PURCHASE LOCK
--==================================================

-- Prevents double-clicking / multiple remote calls
-- from purchasing at the same time.

local PurchaseBusy =
	{}


--==================================================
-- VALID PURCHASE AMOUNTS
--==================================================

local VALID_AMOUNTS =
	{
		[1] = true,
		[3] = true,
	}


--==================================================
-- GET PLAYER LUCK STATE
--==================================================

function LuckService.GetLuckState(
	player
)

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return nil,
			"DataNotLoaded"

	end


	local luckLevel =
		data.LuckLevel
		or 0


	local luckMultiplier =
		LuckConfig.GetLuckMultiplier(
			luckLevel
		)


	local buy1Price =
		LuckConfig.GetBulkUpgradePrice(
			luckLevel,
			1
		)


	local buy3Price =
		LuckConfig.GetBulkUpgradePrice(
			luckLevel,
			3
		)


	return {
		LuckLevel =
			luckLevel,

		LuckMultiplier =
			luckMultiplier,

		Buy1Price =
			buy1Price,

		Buy3Price =
			buy3Price,

		Dollars =
			data.Dollars
			or 0,
	}

end


--==================================================
-- VERIFY PLAYER OWNS THE BOARD'S PLOT
--==================================================

local function PlayerOwnsPlot(
	player,
	requestedPlot
)

	if not requestedPlot then

		return false

	end


	local playerPlot =
		PlotService.GetPlayerPlot(
			player
		)


	if not playerPlot then

		return false

	end


	if playerPlot ~= requestedPlot then

		return false

	end


	if requestedPlot:GetAttribute(
		"OwnerUserId"
		) ~= player.UserId then

		return false

	end


	return true

end


--==================================================
-- PURCHASE LUCK
--==================================================

function LuckService.PurchaseLuck(
	player,
	requestedPlot,
	amount
)

	--==================================================
	-- VALIDATE AMOUNT
	--==================================================

	if not VALID_AMOUNTS[
		amount
		] then

		return false,
			"InvalidAmount"

	end


	--==================================================
	-- PURCHASE LOCK
	--==================================================

	if PurchaseBusy[player] then

		return false,
			"PurchaseBusy"

	end


	PurchaseBusy[player] =
		true


	local function Finish(
		success,
		result
	)

		PurchaseBusy[player] =
			nil


		return success,
			result

	end


	--==================================================
	-- VERIFY PLOT OWNERSHIP
	--==================================================

	if not PlayerOwnsPlot(
		player,
		requestedPlot
		) then

		return Finish(
			false,
			"NotYourPlot"
		)

	end


	--==================================================
	-- GET DATA
	--==================================================

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return Finish(
			false,
			"DataNotLoaded"
		)

	end


	--==================================================
	-- CURRENT LUCK LEVEL
	--==================================================

	local currentLuckLevel =
		data.LuckLevel
		or 0


	--==================================================
	-- SERVER CALCULATES PRICE
	--==================================================

	-- The client NEVER tells the server what
	-- the price should be.

	local price =
		LuckConfig.GetBulkUpgradePrice(
			currentLuckLevel,
			amount
		)


	--==================================================
	-- CHECK DOLLARS
	--==================================================

	local currentDollars =
		data.Dollars
		or 0


	if currentDollars < price then

		return Finish(
			false,
			"NotEnoughDollars"
		)

	end


	--==================================================
	-- DEDUCT DOLLARS
	--==================================================

	local newDollars =
		currentDollars
	- price


	local moneySuccess =
		CurrencyService.SetDollars(
			player,
			newDollars
		)


	if not moneySuccess then

		return Finish(
			false,
			"CurrencyUpdateFailed"
		)

	end


	--==================================================
	-- INCREASE LUCK LEVEL
	--==================================================

	data.LuckLevel =
		currentLuckLevel
		+ amount


	--==================================================
	-- UPDATE NORMAL CURRENCY UI
	--==================================================

	-- SetDollars updates Dollars.
	--
	-- But Luck has also changed, so send the full
	-- currency state again so the player's existing
	-- Luck display updates immediately.

	CurrencyService.SendCurrencyState(
		player
	)
	
	--==================================================
	-- PURCHASE SUCCESS FEEDBACK
	--==================================================

	PlayerFeedbackService.Send(
		player,
		"PurchaseSuccess"
	)


	--==================================================
	-- NEW STATE
	--==================================================

	local newLuckLevel =
		data.LuckLevel


	local newLuckMultiplier =
		LuckConfig.GetLuckMultiplier(
			newLuckLevel
		)


	local newBuy1Price =
		LuckConfig.GetBulkUpgradePrice(
			newLuckLevel,
			1
		)


	local newBuy3Price =
		LuckConfig.GetBulkUpgradePrice(
			newLuckLevel,
			3
		)


	return Finish(
		true,
		{
			PurchasedAmount =
				amount,

			PricePaid =
				price,

			LuckLevel =
				newLuckLevel,

			LuckMultiplier =
				newLuckMultiplier,

			Dollars =
				newDollars,

			Buy1Price =
				newBuy1Price,

			Buy3Price =
				newBuy3Price,
		}
	)

end


--==================================================
-- CLEANUP
--==================================================

function LuckService.CleanupPlayer(
	player
)

	PurchaseBusy[player] =
		nil

end


return LuckService
