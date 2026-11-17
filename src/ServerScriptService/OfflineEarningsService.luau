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


local CurrencyService =
	require(
		script.Parent
		:WaitForChild("CurrencyService")
	)


local PumpkinConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("PumpkinConfig")
	)


local GameConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("GameConfig")
	)


--==================================================
-- SERVICE
--==================================================

local OfflineEarningsService = {}


--==================================================
-- SETTINGS
--==================================================

local MAX_OFFLINE_SECONDS =
	GameConfig.OfflineEarnings.MaxOfflineSeconds
	or (8 * 60 * 60)


-- Players now receive 40% of what they would
-- normally have generated while online.

local OFFLINE_EARNINGS_RATE =
	0.40


--==================================================
-- GET TOTAL MONEY PER SECOND
--==================================================

local function GetTotalMoneyPerSecond(
	data
)

	if type(data.PlacedPumpkins)
		~= "table" then

		return 0

	end


	local totalMoneyPerSecond =
		0


	-- Only pumpkins that are still placed
	-- contribute to offline earnings.

	for _, record in ipairs(
		data.PlacedPumpkins
		) do

		local pumpkinId =
			record.PumpkinId


		if type(pumpkinId)
			== "string" then

			local pumpkinInfo =
				PumpkinConfig.GetPumpkin(
					pumpkinId
				)


			if pumpkinInfo then

				local moneyPerSecond =
					pumpkinInfo.MoneyPerSecond
					or 0


				if type(moneyPerSecond)
					== "number"
					and moneyPerSecond > 0 then

					totalMoneyPerSecond +=
						moneyPerSecond

				end

			end

		end

	end


	return totalMoneyPerSecond

end


--==================================================
-- CALCULATE NEW OFFLINE EARNINGS
--==================================================

function OfflineEarningsService.CalculateForPlayer(
	player
)

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return 0

	end


	local currentTime =
		os.time()


	local lastSeen =
		data.LastSeenUnixTime
		or 0


	--==================================================
	-- FIRST EVER JOIN
	--==================================================

	if lastSeen <= 0 then

		data.LastSeenUnixTime =
			currentTime


		return data.PendingOfflineEarnings
			or 0

	end


	--==================================================
	-- TIME OFFLINE
	--==================================================

	local offlineSeconds =
		math.max(
			0,
			currentTime - lastSeen
		)


	offlineSeconds =
		math.min(
			offlineSeconds,
			MAX_OFFLINE_SECONDS
		)


	--==================================================
	-- PLACED PUMPKIN PRODUCTION
	--==================================================

	local totalMoneyPerSecond =
		GetTotalMoneyPerSecond(
			data
		)


	--==================================================
	-- FULL OFFLINE PRODUCTION
	--==================================================

	local fullOfflineEarnings =
		totalMoneyPerSecond
		* offlineSeconds


	--==================================================
	-- 40% OFFLINE EARNINGS
	--==================================================

	-- Example:
	--
	-- Full production = $10,000
	--
	-- $10,000 * 0.40
	-- = $4,000

	local newlyEarned =
		math.floor(
			fullOfflineEarnings
			* OFFLINE_EARNINGS_RATE
		)


	--==================================================
	-- PRESERVE UNCLAIMED REWARD
	--==================================================

	if type(data.PendingOfflineEarnings)
		~= "number" then

		data.PendingOfflineEarnings =
			0

	end


	if newlyEarned > 0 then

		data.PendingOfflineEarnings +=
			newlyEarned

	end


	--==================================================
	-- START OF CURRENT SESSION
	--==================================================

	data.LastSeenUnixTime =
		currentTime


	return data.PendingOfflineEarnings

end


--==================================================
-- GET PENDING OFFLINE EARNINGS
--==================================================

function OfflineEarningsService.GetPendingEarnings(
	player
)

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return 0

	end


	local amount =
		data.PendingOfflineEarnings
		or 0


	if type(amount)
		~= "number" then

		return 0

	end


	return math.max(
		0,
		amount
	)

end


--==================================================
-- CLAIM WITH MULTIPLIER
--==================================================

local function ClaimWithMultiplier(
	player,
	multiplier
)

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false,
			0,
			"DataNotLoaded"

	end


	local baseAmount =
		data.PendingOfflineEarnings
		or 0


	if type(baseAmount)
		~= "number"
		or baseAmount <= 0 then

		return false,
			0,
			"NothingToClaim"

	end


	--==================================================
	-- VALIDATE MULTIPLIER
	--==================================================

	if multiplier ~= 1
		and multiplier ~= 2 then

		return false,
			0,
			"InvalidMultiplier"

	end


	--==================================================
	-- CALCULATE PAYOUT
	--==================================================

	local payoutAmount =
		baseAmount
		* multiplier


	--==================================================
	-- RESET FIRST
	--==================================================

	-- Reset before giving currency so the same
	-- reward cannot be claimed twice.

	data.PendingOfflineEarnings =
		0


	--==================================================
	-- PAY PLAYER
	--==================================================

	local success =
		CurrencyService.AddDollars(
			player,
			payoutAmount
		)


	if not success then

		-- Restore the ORIGINAL pending amount.
		--
		-- Do not restore payoutAmount because x2 is
		-- only applied when the product succeeds.

		data.PendingOfflineEarnings =
			baseAmount


		return false,
			0,
			"CouldNotAddDollars"

	end


	return true,
		payoutAmount,
		nil

end


--==================================================
-- CLAIM NORMAL OFFLINE EARNINGS
--==================================================

function OfflineEarningsService.Claim(
	player
)

	return ClaimWithMultiplier(
		player,
		1
	)

end


--==================================================
-- CLAIM X2 OFFLINE EARNINGS
--==================================================

function OfflineEarningsService.ClaimX2(
	player
)

	return ClaimWithMultiplier(
		player,
		2
	)

end


--==================================================
-- UPDATE LAST SEEN
--==================================================

function OfflineEarningsService.UpdateLastSeen(
	player
)

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false

	end


	data.LastSeenUnixTime =
		os.time()


	return true

end


return OfflineEarningsService
