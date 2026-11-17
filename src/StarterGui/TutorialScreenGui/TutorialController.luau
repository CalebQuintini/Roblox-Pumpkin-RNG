--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


local RunService =
	game:GetService("RunService")


--==================================================
-- PLAYER
--==================================================

local player =
	Players.LocalPlayer


--==================================================
-- GUI
--==================================================

local gui =
	script.Parent


local rollFrame =
	gui:WaitForChild(
		"RollAPumpkinTutorialFrame"
	)


local buyFrame =
	gui:WaitForChild(
		"BuyThePumpkinTutorialFrame"
	)


local placeFrame =
	gui:WaitForChild(
		"PlaceAPumpkinTutorialFrame"
	)


local completeFrame =
	gui:WaitForChild(
		"CompleteTutorialFrame"
	)


--==================================================
-- REMOTES
--==================================================

local TutorialRemotes =
	ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild("Tutorial")


local ShowCompleteTutorial =
	TutorialRemotes
	:WaitForChild(
		"ShowCompleteTutorial"
	)


--==================================================
-- WORLD
--==================================================

local Plots =
	workspace:WaitForChild(
		"Plots"
	)


--==================================================
-- TUTORIAL STEPS
--==================================================

local STEP_ROLL =
	1


local STEP_BUY =
	2


local STEP_PLACE =
	3


--==================================================
-- GUIDE BEAM SETTINGS
--==================================================

-- Same world-space guide style used by the stealing
-- system: an arrow-textured Beam from the player
-- toward the current tutorial target.

local GUIDE_TEXTURE =
	"rbxassetid://16848361091"


local GUIDE_WIDTH = 2.9


local GUIDE_TEXTURE_LENGTH =
	2


local GUIDE_TEXTURE_SPEED =
	2


--==================================================
-- STATE
--==================================================

local currentStep =
	nil


local currentTarget =
	nil


local guideBeam =
	nil


local playerAttachment =
	nil


local targetAttachment =
	nil


local completeMessageId =
	0


--==================================================
-- FIND PLAYER'S OWN PLOT
--==================================================

local function FindOwnPlot()

	for _, plot in ipairs(
		Plots:GetChildren()
		) do

		if plot:GetAttribute(
			"OwnerUserId"
			) == player.UserId then

			return plot

		end

	end


	return nil

end


--==================================================
-- FIND BASEPART FROM OBJECT
--==================================================

local function FindTargetPart(
	object
)

	if not object then

		return nil

	end


	if object:IsA(
		"BasePart"
		) then

		return object

	end


	if object:IsA(
		"Model"
		) then

		if object.PrimaryPart then

			return object.PrimaryPart

		end

	end


	return object:FindFirstChildWhichIsA(
		"BasePart",
		true
	)

end


--==================================================
-- FIND ROLL SYSTEM
--==================================================

local function FindRollSystem()

	local plot =
		FindOwnPlot()


	if not plot then

		return nil

	end


	local rollArea =
		plot:FindFirstChild(
			"RollArea"
		)


	if not rollArea then

		return nil

	end


	return rollArea:FindFirstChild(
		"RollSystem"
	)

end


--==================================================
-- FIND ROLL BUTTON TARGET
--==================================================

local function FindRollButtonTarget()

	local rollSystem =
		FindRollSystem()


	if not rollSystem then

		return nil

	end


	local rollButton =
		rollSystem:FindFirstChild(
			"RollButton"
		)


	if not rollButton then

		return nil

	end


	local redButton =
		rollButton:FindFirstChild(
			"RedButton",
			true
		)


	if redButton
		and redButton:IsA(
			"BasePart"
		) then

		return redButton

	end


	return FindTargetPart(
		rollButton
	)

end


--==================================================
-- FIND ROLLED PUMPKIN TARGET
--==================================================

local function FindRolledPumpkinTarget()

	local rollSystem =
		FindRollSystem()


	if not rollSystem then

		return nil

	end


	-- Prefer the actual rolled pumpkin created by
	-- RollController.

	local resultModel =
		workspace:FindFirstChild(
			"CurrentRollResult"
		)


	if resultModel
		and resultModel:IsA(
			"Model"
		) then

		local resultPart =
			FindTargetPart(
				resultModel
			)


		if resultPart then

			return resultPart

		end

	end


	-- The server can advance to Step 2 before the
	-- client's reveal animation has finished.
	--
	-- Until CurrentRollResult exists, point at the
	-- same world position used by RollController.

	local rollPosition =
		rollSystem:FindFirstChild(
			"RollPumpkinPosition"
		)


	return FindTargetPart(
		rollPosition
	)

end


--==================================================
-- FIND PLOT PLACEMENT TARGET
--==================================================

local function FindPlotTarget()

	local plot =
		FindOwnPlot()


	if not plot then

		return nil

	end


	local plotFloor =
		plot:FindFirstChild(
			"PlotFloor"
		)


	if plotFloor
		and plotFloor:IsA(
			"BasePart"
		) then

		return plotFloor

	end


	return nil

end


--==================================================
-- FIND TARGET FOR STEP
--==================================================

local function FindTargetForStep(
	step
)

	if step == STEP_ROLL then

		return FindRollButtonTarget()

	end


	if step == STEP_BUY then

		return FindRolledPumpkinTarget()

	end


	if step == STEP_PLACE then

		return FindPlotTarget()

	end


	return nil

end


--==================================================
-- DESTROY TARGET ATTACHMENT
--==================================================

local function DestroyTargetAttachment()

	if targetAttachment then

		targetAttachment:Destroy()


		targetAttachment =
			nil

	end


	currentTarget =
		nil

end


--==================================================
-- DESTROY GUIDE
--==================================================

local function DestroyGuide()

	if guideBeam then

		guideBeam:Destroy()


		guideBeam =
			nil

	end


	if playerAttachment then

		playerAttachment:Destroy()


		playerAttachment =
			nil

	end


	DestroyTargetAttachment()

end


--==================================================
-- GET PLAYER ROOT PART
--==================================================

local function GetPlayerRootPart()

	local character =
		player.Character


	if not character then

		return nil

	end


	return character:FindFirstChild(
		"HumanoidRootPart"
	)

end


--==================================================
-- GET / CREATE PLAYER ATTACHMENT
--==================================================

local function GetOrCreatePlayerAttachment()

	local rootPart =
		GetPlayerRootPart()


	if not rootPart then

		return nil

	end


	if playerAttachment
		and playerAttachment.Parent
		== rootPart then

		return playerAttachment

	end


	if playerAttachment then

		playerAttachment:Destroy()

	end


	playerAttachment =
		Instance.new(
			"Attachment"
		)


	playerAttachment.Name =
		"TutorialGuidePlayerAttachment"


	playerAttachment.Position =
		Vector3.new(
			0,
			1,
			0
		)


	playerAttachment.Parent =
		rootPart


	return playerAttachment

end


--==================================================
-- CREATE GUIDE BEAM
--==================================================

local function GetOrCreateGuideBeam()

	local attachment =
		GetOrCreatePlayerAttachment()


	if not attachment then

		return nil

	end


	if guideBeam
		and guideBeam.Parent then

		guideBeam.Attachment0 =
			attachment


		return guideBeam

	end


	guideBeam =
		Instance.new(
			"Beam"
		)


	guideBeam.Name =
		"TutorialGuideBeam"


	guideBeam.Attachment0 =
		attachment


	guideBeam.FaceCamera =
		true


	guideBeam.Width0 =
		GUIDE_WIDTH


	guideBeam.Width1 =
		GUIDE_WIDTH


	guideBeam.Texture =
		GUIDE_TEXTURE


	guideBeam.TextureMode =
		Enum.TextureMode.Wrap


	guideBeam.TextureLength =
		GUIDE_TEXTURE_LENGTH


	guideBeam.TextureSpeed =
		GUIDE_TEXTURE_SPEED


	guideBeam.LightEmission =
		1


	guideBeam.Enabled =
		false


	guideBeam.Parent =
		attachment


	return guideBeam

end


--==================================================
-- SET GUIDE TARGET
--==================================================

local function SetGuideTarget(
	targetPart
)

	if not targetPart
		or not targetPart:IsA(
			"BasePart"
		) then

		if guideBeam then

			guideBeam.Enabled =
				false

		end


		DestroyTargetAttachment()


		return

	end


	-- Target has not changed.

	if currentTarget
		== targetPart
		and targetAttachment
		and targetAttachment.Parent
		== targetPart then

		local beam =
			GetOrCreateGuideBeam()


		if beam then

			beam.Attachment1 =
				targetAttachment


			beam.Enabled =
				true

		end


		return

	end


	-- Target changed.

	DestroyTargetAttachment()


	currentTarget =
		targetPart


	targetAttachment =
		Instance.new(
			"Attachment"
		)


	targetAttachment.Name =
		"TutorialGuideTargetAttachment"


	targetAttachment.Parent =
		targetPart


	local beam =
		GetOrCreateGuideBeam()


	if not beam then

		return

	end


	beam.Attachment1 =
		targetAttachment


	beam.Enabled =
		true

end


--==================================================
-- HIDE MAIN TUTORIAL FRAMES
--==================================================

local function HideTutorialFrames()

	rollFrame.Visible =
		false


	buyFrame.Visible =
		false


	placeFrame.Visible =
		false

end


--==================================================
-- UPDATE TUTORIAL
--==================================================

local function UpdateTutorial()

	HideTutorialFrames()


	local active =
		player:GetAttribute(
			"TutorialActive"
		)


	if active ~= true then

		currentStep =
			nil


		completeFrame.Visible =
			false


		DestroyGuide()


		return

	end


	local step =
		player:GetAttribute(
			"TutorialStep"
		)


	currentStep =
		step


	--==================================================
	-- STEP 1 - ROLL
	--==================================================

	if step == STEP_ROLL then

		rollFrame.Visible =
			true


		--==================================================
		-- STEP 2 - BUY
		--==================================================

	elseif step == STEP_BUY then

		buyFrame.Visible =
			true


		--==================================================
		-- STEP 3 - PLACE
		--==================================================

	elseif step == STEP_PLACE then

		placeFrame.Visible =
			true


	else

		DestroyGuide()


		return

	end


	SetGuideTarget(
		FindTargetForStep(
			step
		)
	)

end


--==================================================
-- KEEP GUIDE TARGET UPDATED
--==================================================

RunService.RenderStepped:Connect(
	function()

		if player:GetAttribute(
			"TutorialActive"
			) ~= true then

			return

		end


		local step =
			player:GetAttribute(
				"TutorialStep"
			)


		if step
			~= currentStep then

			UpdateTutorial()


			return

		end


		local target =
			FindTargetForStep(
				step
			)


		SetGuideTarget(
			target
		)

	end
)


--==================================================
-- CHARACTER RESPAWN
--==================================================

player.CharacterAdded:Connect(
	function()

		-- The old HumanoidRootPart and its attachment
		-- disappear on respawn.

		if playerAttachment then

			playerAttachment =
				nil

		end


		if guideBeam then

			guideBeam =
				nil

		end


		task.wait(
			0.5
		)


		UpdateTutorial()

	end
)


--==================================================
-- COMPLETE-TUTORIAL MESSAGE
--==================================================

ShowCompleteTutorial.OnClientEvent:Connect(
	function()

		if player:GetAttribute(
			"TutorialActive"
			) ~= true then

			return

		end


		completeMessageId +=
			1


		local myId =
			completeMessageId


		completeFrame.Visible =
			true


		task.delay(
			1.5,

			function()

				if completeMessageId
					~= myId then

					return

				end


				completeFrame.Visible =
					false

			end
		)

	end
)


--==================================================
-- TUTORIAL ACTIVE CHANGED
--==================================================

player:GetAttributeChangedSignal(
	"TutorialActive"
):Connect(
	function()

		UpdateTutorial()

	end
)


--==================================================
-- TUTORIAL STEP CHANGED
--==================================================

player:GetAttributeChangedSignal(
	"TutorialStep"
):Connect(
	function()

		UpdateTutorial()

	end
)


--==================================================
-- INITIAL GUI STATE
--==================================================

rollFrame.Visible =
	false


buyFrame.Visible =
	false


placeFrame.Visible =
	false


completeFrame.Visible =
	false


--==================================================
-- INITIALIZE
--==================================================

task.spawn(
	function()

		-- Plot assignment may happen shortly after
		-- the player's GUI loads.

		for _ = 1, 100 do

			if FindOwnPlot() then

				break

			end


			task.wait(
				0.1
			)

		end


		UpdateTutorial()

	end
)
