--==================================================
-- SERVICES
--==================================================

local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)


local ServerScriptService =
	game:GetService(
		"ServerScriptService"
	)


--==================================================
-- MODULES
--==================================================

local PlayerDataService =
	require(
		ServerScriptService
		:WaitForChild(
			"PlayerDataService"
		)
	)


local GameAnalyticsService =
	require(
		ServerScriptService
		:WaitForChild(
			"GameAnalyticsService"
		)
	)


--==================================================
-- MODULE
--==================================================

local TutorialService = {}


--==================================================
-- TUTORIAL STEPS
--==================================================

TutorialService.STEP_ROLL =
	1


TutorialService.STEP_BUY =
	2


TutorialService.STEP_PLACE =
	3


TutorialService.STEP_COMPLETE =
	4


--==================================================
-- REMOTES ROOT
--==================================================

local Remotes =
	ReplicatedStorage
	:FindFirstChild(
		"Remotes"
	)


if not Remotes then

	Remotes =
		Instance.new(
			"Folder"
		)


	Remotes.Name =
		"Remotes"


	Remotes.Parent =
		ReplicatedStorage

end


--==================================================
-- TUTORIAL REMOTE FOLDER
--==================================================

local TutorialRemotes =
	Remotes:FindFirstChild(
		"Tutorial"
	)


if not TutorialRemotes then

	TutorialRemotes =
		Instance.new(
			"Folder"
		)


	TutorialRemotes.Name =
		"Tutorial"


	TutorialRemotes.Parent =
		Remotes

end


--==================================================
-- GET / CREATE REMOTE EVENT
--==================================================

local function GetOrCreateRemoteEvent(
	name
)

	local existing =
		TutorialRemotes:FindFirstChild(
			name
		)


	if existing then

		if existing:IsA(
			"RemoteEvent"
			) then

			return existing

		end


		warn(
			"[TutorialService]",
			name,
			"exists but is not a RemoteEvent."
		)


		return nil

	end


	local remote =
		Instance.new(
			"RemoteEvent"
		)


	remote.Name =
		name


	remote.Parent =
		TutorialRemotes


	return remote

end


--==================================================
-- REMOTES
--==================================================

local ShowCompleteTutorial =
	GetOrCreateRemoteEvent(
		"ShowCompleteTutorial"
	)


--==================================================
-- VALIDATE STEP
--==================================================

local function ValidateStep(
	step
)

	step =
		tonumber(
			step
		)


	if not step then

		return TutorialService.STEP_ROLL

	end


	step =
		math.floor(
			step
		)


	if step
		< TutorialService.STEP_ROLL then

		return TutorialService.STEP_ROLL

	end


	if step
		> TutorialService.STEP_COMPLETE then

		return TutorialService.STEP_COMPLETE

	end


	return step

end


--==================================================
-- APPLY RUNTIME ATTRIBUTES
--==================================================

local function ApplyRuntimeState(
	player,
	active,
	step
)

	if not player then

		return

	end


	player:SetAttribute(
		"TutorialActive",
		active == true
	)


	player:SetAttribute(
		"TutorialStep",
		step
	)

end


--==================================================
-- SYNC PLAYER
--==================================================

function TutorialService.SyncPlayer(
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
	-- ALREADY COMPLETED
	--==================================================

	if data.TutorialCompleted
		== true then

		data.TutorialStep =
			TutorialService.STEP_COMPLETE


		ApplyRuntimeState(
			player,
			false,
			TutorialService.STEP_COMPLETE
		)


		return true

	end


	--==================================================
	-- ACTIVE TUTORIAL
	--==================================================

	local step =
		ValidateStep(
			data.TutorialStep
		)


	-- If TutorialCompleted is false, the player should
	-- never remain on STEP_COMPLETE.
	--
	-- Recover safely to Step 1 instead.

	if step
		== TutorialService.STEP_COMPLETE then

		step =
			TutorialService.STEP_ROLL

	end


	data.TutorialCompleted =
		false


	data.TutorialStep =
		step


	ApplyRuntimeState(
		player,
		true,
		step
	)


	return true

end


--==================================================
-- IS ACTIVE
--==================================================

function TutorialService.IsActive(
	player
)

	if not player then

		return false

	end


	return player:GetAttribute(
		"TutorialActive"
	) == true

end


--==================================================
-- GET STEP
--==================================================

function TutorialService.GetStep(
	player
)

	if not player then

		return nil

	end


	local step =
		player:GetAttribute(
			"TutorialStep"
		)


	if type(step)
		~= "number" then

		return nil

	end


	return step

end


--==================================================
-- IS STEP
--==================================================

function TutorialService.IsStep(
	player,
	step
)

	if not TutorialService.IsActive(
		player
		) then

		return false

	end


	return TutorialService.GetStep(
		player
	) == step

end


--==================================================
-- SET STEP
--==================================================

local function SetStep(
	player,
	newStep
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


	if data.TutorialCompleted
		== true then

		return false,
			"TutorialAlreadyCompleted"

	end


	newStep =
		ValidateStep(
			newStep
		)


	if newStep
		== TutorialService.STEP_COMPLETE then

		return false,
			"UseComplete"

	end


	data.TutorialStep =
		newStep


	data.TutorialCompleted =
		false


	ApplyRuntimeState(
		player,
		true,
		newStep
	)


	return true

end


--==================================================
-- ADVANCE TO BUY
--==================================================

function TutorialService.AdvanceToBuy(
	player
)

	if not TutorialService.IsStep(
		player,
		TutorialService.STEP_ROLL
		) then

		return false,
			"WrongTutorialStep"

	end


	return SetStep(
		player,
		TutorialService.STEP_BUY
	)

end


--==================================================
-- ADVANCE TO PLACE
--==================================================

function TutorialService.AdvanceToPlace(
	player
)

	if not TutorialService.IsStep(
		player,
		TutorialService.STEP_BUY
		) then

		return false,
			"WrongTutorialStep"

	end


	return SetStep(
		player,
		TutorialService.STEP_PLACE
	)

end


--==================================================
-- COMPLETE TUTORIAL
--==================================================

function TutorialService.Complete(
	player
)

	if not player then

		return false,
			"InvalidPlayer"

	end


	if not TutorialService.IsStep(
		player,
		TutorialService.STEP_PLACE
		) then

		return false,
			"WrongTutorialStep"

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
	-- MARK TUTORIAL COMPLETE
	--==================================================

	data.TutorialCompleted =
		true


	data.TutorialStep =
		TutorialService.STEP_COMPLETE


	--==================================================
	-- APPLY RUNTIME STATE
	--==================================================

	ApplyRuntimeState(
		player,
		false,
		TutorialService.STEP_COMPLETE
	)


	--==================================================
	-- ANALYTICS - TUTORIAL COMPLETED
	--==================================================

	GameAnalyticsService.LogOnboardingStep(
		player,
		GameAnalyticsService.OnboardingSteps.TutorialCompleted
	)


	return true

end


--==================================================
-- SHOW COMPLETE-TUTORIAL MESSAGE
--==================================================

function TutorialService.ShowCompleteTutorial(
	player
)

	if not player then

		return

	end


	if not TutorialService.IsActive(
		player
		) then

		return

	end


	if ShowCompleteTutorial then

		ShowCompleteTutorial:FireClient(
			player
		)

	end

end


--==================================================
-- STARTED
--==================================================

print(
	"[TutorialService] Started"
)


return TutorialService
