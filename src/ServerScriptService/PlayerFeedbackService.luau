--==================================================
-- SERVICES
--==================================================

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


--==================================================
-- REMOTES
--==================================================

local remotes =
	ReplicatedStorage:WaitForChild(
		"Remotes"
	)


local playerFeedbackFolder =
	remotes:WaitForChild(
		"PlayerFeedback"
	)


local showFeedback =
	playerFeedbackFolder:WaitForChild(
		"ShowFeedback"
	)


--==================================================
-- MODULE
--==================================================

local PlayerFeedbackService = {}


--==================================================
-- VALID FEEDBACK TYPES
--==================================================

local VALID_FEEDBACK_TYPES =
	{
		PurchaseSuccess =
		true,

		PurchaseDeclined =
		true,

		-- Uses the same PurchaseDeclined sound,
		-- but does NOT show the Can't Afford UI.
		BarrierDeclined =
		true,
		
		BarrierSuccessfullyActivated =
		true,

		PumpkinMoneyCollect =
		true,

		PumpkinPlacePickup =
		true,

		PlayerBaseUnlocked =
		true,
	}


--==================================================
-- SEND FEEDBACK
--==================================================

function PlayerFeedbackService.Send(
	player,
	feedbackType
)

	if not player then

		return false

	end


	if not VALID_FEEDBACK_TYPES[
		feedbackType
		] then

		warn(
			"[PlayerFeedbackService] Invalid feedback type:",
			feedbackType
		)


		return false

	end


	showFeedback:FireClient(
		player,
		feedbackType
	)


	return true

end


return PlayerFeedbackService
