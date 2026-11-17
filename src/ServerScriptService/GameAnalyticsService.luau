--==================================================
-- SERVICES
--==================================================

local AnalyticsService =
	game:GetService("AnalyticsService")


--==================================================
-- MODULE
--==================================================

local GameAnalyticsService = {}


--==================================================
-- ONBOARDING STEPS
--==================================================

GameAnalyticsService.OnboardingSteps = {

	JoinedGame = 1,

	RolledFirstPumpkin = 2,

	BoughtFirstPumpkin = 3,

	PlacedFirstPumpkin = 4,

	TutorialCompleted = 5,
}


--==================================================
-- ONBOARDING STEP NAMES
--==================================================

GameAnalyticsService.OnboardingStepNames = {

	[1] = "Joined Game",

	[2] = "Rolled First Pumpkin",

	[3] = "Bought First Pumpkin",

	[4] = "Placed First Pumpkin",

	[5] = "Tutorial Completed",
}


--==================================================
-- LOG ONBOARDING STEP
--==================================================

function GameAnalyticsService.LogOnboardingStep(
	player,
	step
)

	--==================================================
	-- VALIDATE PLAYER
	--==================================================

	if not player then

		return false

	end


	--==================================================
	-- VALIDATE STEP
	--==================================================

	local stepName = GameAnalyticsService.OnboardingStepNames[step]


	if not stepName then

		warn(
			"[GameAnalyticsService] Invalid onboarding step:",
			step
		)


		return false

	end


	--==================================================
	-- SEND TO ROBLOX ANALYTICS
	--==================================================

	local success,
		errorMessage =
		pcall(
			function()

				AnalyticsService
				:LogOnboardingFunnelStepEvent(
					player,
					step,
					stepName
				)

			end
		)


	if not success then

		warn(
			"[GameAnalyticsService] Failed to log onboarding step:",
			player.Name,
			step,
			stepName,
			errorMessage
		)


		return false

	end


	--==================================================
	-- DEBUG
	--==================================================

	print(
		"[GameAnalyticsService]",
		player.Name,
		"completed onboarding step",
		step,
		stepName
	)


	return true

end


return GameAnalyticsService
