--==================================================
-- LUCK CONFIG
--==================================================

local LuckConfig = {}


--==================================================
-- LUCK PROGRESSION
--==================================================

-- Every purchased upgrade adds +0.15 Luck.
LuckConfig.LuckPerUpgrade =
	0.15


-- Starting Luck when the player has purchased
-- zero upgrades.
LuckConfig.StartingLuck =
	1


--==================================================
-- LUCK PRICE CURVE
--==================================================

-- Reduced from $100.
--
-- Makes the first few Luck upgrades
-- easier for a normal player to reach.

LuckConfig.StartingLuckPrice =
	75


-- Reduced heavily from 135.
--
-- This lowers the steady price increase
-- through the early and middle upgrades.

LuckConfig.LuckLinear =
	60


-- Reduced heavily from 112.5.
--
-- This makes the middle/later upgrades
-- accelerate much less aggressively.

LuckConfig.LuckQuadratic =
	35


-- Reduced from 1.17.
--
-- This is the biggest long-term reduction.
--
-- Because this value compounds every upgrade,
-- lowering it to 1.10 makes high Luck levels
-- significantly more achievable.

LuckConfig.LuckGrowth =
	1.10


--==================================================
-- NO MAXIMUM
--==================================================

-- There is intentionally no MaxLuckLevel.
--
-- Luck can continue increasing as long as the
-- player can afford the increasing upgrade prices.


--==================================================
-- GET LUCK MULTIPLIER
--==================================================

function LuckConfig.GetLuckMultiplier(
	luckLevel
)

	luckLevel =
		math.max(
			0,
			luckLevel or 0
		)


	return LuckConfig.StartingLuck
		+ (
			luckLevel
			* LuckConfig.LuckPerUpgrade
		)

end


--==================================================
-- CALCULATE SINGLE UPGRADE PRICE
--==================================================

function LuckConfig.GetUpgradePrice(
	upgradeNumber
)

	-- Upgrade numbers begin at 1.
	--
	-- Upgrade 1:
	-- n = 0
	--
	-- Upgrade 2:
	-- n = 1
	--
	-- etc.

	upgradeNumber =
		math.max(
			1,
			math.floor(
				upgradeNumber
			)
		)


	local n =
		upgradeNumber - 1


	local price =
		(
			LuckConfig.StartingLuckPrice

			+ LuckConfig.LuckLinear
			* n

			+ LuckConfig.LuckQuadratic
			* n^2
		)

		* LuckConfig.LuckGrowth^n


	return math.round(
		price
	)

end


--==================================================
-- GET PRICE FOR MULTIPLE UPGRADES
--==================================================

function LuckConfig.GetBulkUpgradePrice(
	currentLuckLevel,
	amount
)

	currentLuckLevel =
		math.max(
			0,
			math.floor(
				currentLuckLevel or 0
			)
		)


	amount =
		math.max(
			1,
			math.floor(
				amount or 1
			)
		)


	local totalPrice =
		0


	for offset = 1, amount do

		local upgradeNumber =
			currentLuckLevel
			+ offset


		totalPrice +=
			LuckConfig.GetUpgradePrice(
				upgradeNumber
			)

	end


	return totalPrice

end


return LuckConfig
