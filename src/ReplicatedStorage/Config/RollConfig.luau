--==================================================
-- ROLL CONFIG
--==================================================

local RollConfig = {}


--==================================================
-- ANIMATION
--==================================================

RollConfig.Animation = {

	-- Number of silhouette changes.
	Steps = 19,

	-- Fast beginning.
	StartDelay = 0.001,

	-- Slower ending.
	EndDelay = 0.39,

	-- Controls the slowdown curve.
	SlowdownPower = 2.9,


	-- Silhouette scaling.
	SilhouetteStartScale = 0.78,
	SilhouettePopScale = 1.05,
	SilhouetteNormalScale = 1,

	SilhouettePopTime = 0.035, --SilhouettePopTime = 0.08,
	SilhouetteSettleTime = 0.03, --SilhouetteSettleTime = 0.07,


	-- Result scaling.
	ResultStartScale = 0.65,
	ResultPopScale = 1.18,
	ResultNormalScale = 1,

	ResultPopTime = 0.18,
	ResultSettleTime = 0.14,
}


--==================================================
-- RNG
--==================================================

RollConfig.RNG = {

	--==================================================
	-- MINIMUM LUCK POWER
	--==================================================

	-- Controls how strongly very common pumpkins
	-- benefit from player Luck.
	--
	-- Lower BaseOneIn pumpkins stay closer to this
	-- value.
	--
	-- Example:
	--
	-- A common pumpkin may use roughly:
	--
	-- Luck ^ 0.35
	--
	-- instead of receiving the full Luck multiplier.

	MinimumLuckPower = 0.35,


	--==================================================
	-- MAXIMUM LUCK POWER
	--==================================================

	-- Controls the strongest possible effect Luck
	-- can have on very rare pumpkins.
	--
	-- 1.00 means the rarest pumpkins can receive
	-- approximately the full Luck multiplier.
	--
	-- Example:
	--
	-- x10 Luck
	--
	-- Very rare pumpkin:
	--
	-- approximately 10x its base probability.
	--
	-- Luck power is capped here so extremely large
	-- BaseOneIn values cannot make Luck scale
	-- infinitely stronger.

	MaximumLuckPower = 1.00,


	--==================================================
	-- LUCK RARITY SCALE
	--==================================================

	-- Controls how quickly a pumpkin moves from
	-- MinimumLuckPower toward MaximumLuckPower
	-- based on its BaseOneIn.
	--
	-- PumpkinRollService uses:
	--
	-- log10(BaseOneIn) / LuckRarityScale
	--
	-- and clamps the result between 0 and 1.
	--
	-- Your current target maximum is roughly:
	--
	-- BaseOneIn = 30000
	--
	-- log10(30000) ~= 4.477
	--
	-- So using 4.5 means a 1/30K pumpkin receives
	-- almost the full MaximumLuckPower.

	LuckRarityScale = 4.5,


	--==================================================
	-- MINIMUM FALLBACK CHANCE
	--==================================================

	-- Safety limit.
	--
	-- At very high Luck, all explicit non-fallback
	-- pumpkin probabilities may eventually add up
	-- to more than 100%.
	--
	-- If that happens, PumpkinRollService scales
	-- those probabilities down proportionally.
	--
	-- This keeps at least 0.1% probability reserved
	-- for the fallback pumpkin.

	MinimumFallbackChance = 0.001,
}


--==================================================
-- GET STEP DELAY
--==================================================

function RollConfig.GetStepDelay(step)

	local animation =
		RollConfig.Animation


	local progress =
		(step - 1)
		/ (animation.Steps - 1)


	local curvedProgress =
		progress ^ animation.SlowdownPower


	return animation.StartDelay
		+ (
			animation.EndDelay
			- animation.StartDelay
		)
		* curvedProgress

end


--==================================================
-- GET TOTAL ANIMATION DURATION
--==================================================

function RollConfig.GetAnimationDuration()

	local animation =
		RollConfig.Animation


	local total =
		0


	for step = 1, animation.Steps do

		total +=
			animation.SilhouettePopTime


		total +=
			animation.SilhouetteSettleTime


		total +=
			RollConfig.GetStepDelay(
				step
			)

	end


	total +=
		animation.ResultPopTime


	total +=
		animation.ResultSettleTime


	return total

end


return RollConfig
