--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService(
		"Players"
	)


local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)


--==================================================
-- PLAYER
--==================================================

local player =
	Players.LocalPlayer


local playerGui =
	player:WaitForChild(
		"PlayerGui"
	)


--==================================================
-- WORLD
--==================================================

local Plots =
	workspace:WaitForChild(
		"Plots"
	)


--==================================================
-- UI TEMPLATES
--==================================================

-- ReplicatedStorage
-- └── Assets
--     └── UI
--         ├── PumpkinStolenUI
--         └── PlayerPumpkinStealingUI

local Assets =
	ReplicatedStorage
	:WaitForChild(
		"Assets"
	)


local UI =
	Assets:WaitForChild(
		"UI"
	)


local PumpkinStolenTemplate =
	UI:WaitForChild(
		"PumpkinStolenUI"
	)


local PlayerPumpkinStealingTemplate =
	UI:WaitForChild(
		"PlayerPumpkinStealingUI"
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild(
		"Remotes"
	)


local StealRemotes =
	Remotes:WaitForChild(
		"PumpkinSteal"
	)


local StealStateChanged =
	StealRemotes:WaitForChild(
		"StealStateChanged"
	)


local ShowPumpkinStolenUI =
	StealRemotes:WaitForChild(
		"ShowPumpkinStolenUI"
	)


local HidePumpkinStolenUI =
	StealRemotes:WaitForChild(
		"HidePumpkinStolenUI"
	)


--==================================================
-- STATE
--==================================================

local currentlyStealing =
	false


local activeTheftId =
	nil


local activeThiefPlotName =
	nil


--==================================================
-- THIEF UI STATE
--==================================================

local activeStealingFrame =
	nil


--==================================================
-- VICTIM UI STATE
--==================================================

-- [TheftId] = cloned Frame

local activeStolenUIs =
	{}


-- Keeps notification creation order.

local stolenUIOrder =
	{}


--==================================================
-- FOLLOW ARROW / BEAM STATE
--==================================================

local stealGuideBeam =
	nil


local stealGuidePlayerAttachment =
	nil


local stealGuideTargetAttachment =
	nil


--==================================================
-- PROMPT STATE
--==================================================

local connectedPrompts =
	{}


-- [prompt] = previous Enabled state

local stealModePromptStates =
	{}


--==================================================
-- CREATE MAIN SCREEN GUI
--==================================================

local stealScreenGui =
	playerGui:FindFirstChild(
		"PumpkinStealScreenGui"
	)


if not stealScreenGui then

	stealScreenGui =
		Instance.new(
			"ScreenGui"
		)


	stealScreenGui.Name =
		"PumpkinStealScreenGui"


	stealScreenGui.ResetOnSpawn =
		false


	stealScreenGui.IgnoreGuiInset =
		true


	stealScreenGui.DisplayOrder =
		100


	stealScreenGui.ZIndexBehavior =
		Enum.ZIndexBehavior.Sibling


	stealScreenGui.Parent =
		playerGui

end


stealScreenGui.Enabled =
	true


--==================================================
-- IS STEAL PROMPT?
--==================================================

local function IsStealPrompt(
	prompt
)

	return prompt:IsA(
		"ProximityPrompt"
	)
		and prompt.Name
		== "StealPumpkinPrompt"

end


--==================================================
-- GET PUMPKIN MODEL FROM PROMPT
--==================================================

local function GetPumpkinFromPrompt(
	prompt
)

	if not prompt then

		return nil

	end


	return prompt
		:FindFirstAncestorOfClass(
			"Model"
		)

end


--==================================================
-- IS OWN PUMPKIN?
--==================================================

local function IsOwnPumpkinPrompt(
	prompt
)

	local pumpkinModel =
		GetPumpkinFromPrompt(
			prompt
		)


	if not pumpkinModel then

		return false

	end


	local ownerUserId =
		pumpkinModel:GetAttribute(
			"OwnerUserId"
		)


	return ownerUserId
		== player.UserId

end


--==================================================
-- APPLY LOCAL PROMPT RULE
--==================================================

local function ApplyPromptRule(
	prompt
)

	if not IsStealPrompt(
		prompt
		) then

		return

	end


	--==================================================
	-- OWNER NEVER SEES OWN STEAL PROMPT
	--==================================================

	if IsOwnPumpkinPrompt(
		prompt
		) then

		prompt.Enabled =
			false


		return

	end


	--==================================================
	-- HIDE ALL STEAL PROMPTS WHILE STEALING
	--==================================================

	if currentlyStealing then

		if stealModePromptStates[
			prompt
			] == nil then

			stealModePromptStates[prompt] = prompt.Enabled

		end


		prompt.Enabled =
			false

	end

end


--==================================================
-- CONNECT ONE STEAL PROMPT
--==================================================

local function ConnectStealPrompt(
	prompt
)

	if not IsStealPrompt(
		prompt
		) then

		return

	end


	if connectedPrompts[
		prompt
		] then

		return

	end


	connectedPrompts[prompt] = true


	local pumpkinModel =
		GetPumpkinFromPrompt(
			prompt
		)


	--==================================================
	-- INITIAL STATE
	--==================================================

	ApplyPromptRule(
		prompt
	)


	--==================================================
	-- OWNER CHANGED
	--==================================================

	if pumpkinModel then

		pumpkinModel
			:GetAttributeChangedSignal(
				"OwnerUserId"
			)
			:Connect(
				function()

					ApplyPromptRule(
						prompt
					)

				end
			)

	end


	--==================================================
	-- SERVER CHANGED ENABLED
	--==================================================

	prompt
		:GetPropertyChangedSignal(
			"Enabled"
		)
		:Connect(
			function()

				-- Own pumpkin must remain hidden.

				if IsOwnPumpkinPrompt(
					prompt
					)
					and prompt.Enabled then

					prompt.Enabled = false


					return

				end


				-- While carrying a stolen pumpkin,
				-- all other stealing prompts stay hidden.

				if currentlyStealing
					and prompt.Enabled then

					if stealModePromptStates[
						prompt
						] == nil then

						stealModePromptStates[prompt] = true

					end


					prompt.Enabled = false

				end

			end
		)


	--==================================================
	-- CLEANUP
	--==================================================

	prompt.Destroying:Connect(
		function()

			connectedPrompts[prompt] = nil


			stealModePromptStates[prompt] = nil

		end
	)

end


--==================================================
-- CONNECT ALL EXISTING STEAL PROMPTS
--==================================================

local function ConnectAllStealPrompts()

	for _, descendant in ipairs(
		Plots:GetDescendants()
		) do

		if IsStealPrompt(
			descendant
			) then

			ConnectStealPrompt(
				descendant
			)

		end

	end

end


--==================================================
-- HIDE OTHER STEAL PROMPTS
--==================================================

local function HideOtherStealPrompts()

	for _, descendant in ipairs(
		Plots:GetDescendants()
		) do

		if IsStealPrompt(
			descendant
			) then

			if stealModePromptStates[
				descendant
				] == nil then

				stealModePromptStates[descendant] = descendant.Enabled

			end


			descendant.Enabled =
				false

		end

	end

end


--==================================================
-- RESTORE STEAL PROMPTS
--==================================================

local function RestoreStealPrompts()

	for prompt, previousEnabled in pairs(
		stealModePromptStates
		) do

		if prompt
			and prompt.Parent then

			-- Own pumpkin remains hidden.

			if IsOwnPumpkinPrompt(
				prompt
				) then

				prompt.Enabled =
					false


			else

				prompt.Enabled =
					previousEnabled
					== true

			end

		end

	end


	stealModePromptStates =
		{}


	-- Re-apply ownership rules.

	for prompt in pairs(
		connectedPrompts
		) do

		if prompt
			and prompt.Parent
			and IsOwnPumpkinPrompt(
				prompt
			) then

			prompt.Enabled =
				false

		end

	end

end


--==================================================
-- SHOW PLAYER STEALING UI
--==================================================

local function ShowStealingUI()

	if activeStealingFrame then

		activeStealingFrame:Destroy()


		activeStealingFrame =
			nil

	end


	local clone =
		PlayerPumpkinStealingTemplate
		:Clone()


	clone.Name =
		"ActivePlayerPumpkinStealingUI"


	clone.Visible =
		true


	-- We deliberately do NOT change:
	--
	-- Position
	-- Size
	-- AnchorPoint
	-- Rotation
	--
	-- It keeps the layout you created in Studio.

	clone.Parent =
		stealScreenGui


	activeStealingFrame =
		clone


	print(
		"[PumpkinStealController] PlayerPumpkinStealingUI shown"
	)

end


--==================================================
-- HIDE PLAYER STEALING UI
--==================================================

local function HideStealingUI()

	if activeStealingFrame then

		activeStealingFrame:Destroy()


		activeStealingFrame =
			nil

	end


	print(
		"[PumpkinStealController] PlayerPumpkinStealingUI hidden"
	)

end


--==================================================
-- RESTACK VICTIM UIS
--==================================================

local function RestackVictimUIs()

	local validOrder =
		{}


	for _, theftId in ipairs(
		stolenUIOrder
		) do

		local frame = activeStolenUIs[theftId]


		if frame
			and frame.Parent then

			table.insert(
				validOrder,
				theftId
			)

		end

	end


	stolenUIOrder =
		validOrder


	--==================================================
	-- FIRST UI USES YOUR ORIGINAL STUDIO POSITION
	--==================================================

	local basePosition =
		PumpkinStolenTemplate.Position


	local baseSize =
		PumpkinStolenTemplate.Size


	local padding = 8


	for index, theftId in ipairs(
		stolenUIOrder
		) do

		local frame = activeStolenUIs[theftId]


		if frame then

			local offsetIndex =
				index - 1


			frame.Position =
				UDim2.new(
					basePosition.X.Scale,
					basePosition.X.Offset,

					basePosition.Y.Scale
					+ (
						baseSize.Y.Scale
						* offsetIndex
					),

					basePosition.Y.Offset
					+ (
						(
							baseSize.Y.Offset
							+ padding
						)
						* offsetIndex
					)
				)

		end

	end

end


--==================================================
-- SHOW VICTIM STOLEN UI
--==================================================

local function ShowVictimStolenUI(
	theftId,
	thiefName
)

	if type(theftId)
		~= "string" then

		return

	end


	if type(thiefName)
		~= "string" then

		thiefName =
			"Someone"

	end


	if activeStolenUIs[
		theftId
		] then

		return

	end


	--==================================================
	-- CLONE TEMPLATE
	--==================================================

	local clone =
		PumpkinStolenTemplate:Clone()


	clone.Name =
		"PumpkinStolenUI_"
		.. theftId


	clone.Visible =
		true


	clone.Parent =
		stealScreenGui


	--==================================================
	-- CHANGE PLAYER NAME
	--==================================================

	-- PumpkinStolenUI
	-- └── Frame
	--     └── TextLabel

	local innerFrame =
		clone:FindFirstChild(
			"Frame"
		)


	if not innerFrame then

		warn(
			"[PumpkinStealController] PumpkinStolenUI.Frame missing"
		)


	else

		local textLabel =
			innerFrame:FindFirstChild(
				"TextLabel"
			)


		if textLabel
			and textLabel:IsA(
				"TextLabel"
			) then

			textLabel.Text =
				string.gsub(
					textLabel.Text,
					"PlayerName",
					thiefName
				)

		else

			warn(
				"[PumpkinStealController] PumpkinStolenUI.Frame.TextLabel missing"
			)

		end

	end


	--==================================================
	-- STORE
	--==================================================

	activeStolenUIs[theftId] = clone


	table.insert(
		stolenUIOrder,
		theftId
	)


	RestackVictimUIs()


	print(
		"[PumpkinStealController] PumpkinStolenUI shown for:",
		thiefName,
		"TheftId:",
		theftId
	)

end


--==================================================
-- HIDE VICTIM STOLEN UI
--==================================================

local function HideVictimStolenUI(
	theftId
)

	if type(theftId)
		~= "string" then

		return

	end


	local clone = activeStolenUIs[theftId]


	if clone then

		clone:Destroy()

	end


	activeStolenUIs[theftId] = nil


	for index, savedTheftId in ipairs(
		stolenUIOrder
		) do

		if savedTheftId
			== theftId then

			table.remove(
				stolenUIOrder,
				index
			)


			break

		end

	end


	RestackVictimUIs()


	print(
		"[PumpkinStealController] PumpkinStolenUI hidden:",
		theftId
	)

end


--==================================================
-- FIND PLAYER'S OWN FRONT FENCE PART
--==================================================

local function FindFrontFencePart(
	plotName
)

	if type(plotName)
		~= "string" then

		return nil

	end


	--==================================================
	-- PLOT
	--==================================================

	local plot =
		Plots:FindFirstChild(
			plotName
		)


	if not plot then

		return nil

	end


	--==================================================
	-- NORMAL BARRIER
	--==================================================

	local normalBarrier =
		plot:FindFirstChild(
			"NormalBarrier"
		)


	if not normalBarrier then

		return nil

	end


	--==================================================
	-- BARRIER MODEL
	--==================================================

	local barrierModel =
		normalBarrier:FindFirstChild(
			"BarrierModel"
		)


	if not barrierModel then

		return nil

	end


	--==================================================
	-- EXISTING FRONT FENCE PART
	--==================================================

	local frontFencePart =
		barrierModel:FindFirstChild(
			"FrontFencePart",
			true
		)


	if not frontFencePart
		or not frontFencePart:IsA(
			"BasePart"
		) then

		return nil

	end


	return frontFencePart

end


--==================================================
-- HIDE FOLLOW ARROW
--==================================================

local function HideReturnArrow()

	--==================================================
	-- BEAM
	--==================================================

	if stealGuideBeam then

		stealGuideBeam:Destroy()


		stealGuideBeam =
			nil

	end


	--==================================================
	-- PLAYER ATTACHMENT
	--==================================================

	if stealGuidePlayerAttachment then

		stealGuidePlayerAttachment:Destroy()


		stealGuidePlayerAttachment =
			nil

	end


	--==================================================
	-- TARGET ATTACHMENT
	--==================================================

	if stealGuideTargetAttachment then

		stealGuideTargetAttachment:Destroy()


		stealGuideTargetAttachment =
			nil

	end

end


--==================================================
-- SHOW FOLLOW ARROW
--==================================================

local function ShowReturnArrow(
	plotName
)

	-- Remove any old arrow first.

	HideReturnArrow()


	--==================================================
	-- FIND PLAYER'S OWN FRONT FENCE
	--==================================================

	local frontFencePart =
		FindFrontFencePart(
			plotName
		)


	if not frontFencePart then

		warn(
			"[PumpkinStealController] Could not find FrontFencePart for:",
			plotName
		)


		return

	end


	--==================================================
	-- CHARACTER
	--==================================================

	local character =
		player.Character


	if not character then

		warn(
			"[PumpkinStealController] Character missing while creating follow arrow"
		)


		return

	end


	--==================================================
	-- HUMANOID ROOT PART
	--==================================================

	local humanoidRootPart =
		character:FindFirstChild(
			"HumanoidRootPart"
		)


	if not humanoidRootPart then

		humanoidRootPart =
			character:WaitForChild(
				"HumanoidRootPart",
				5
			)

	end


	if not humanoidRootPart then

		warn(
			"[PumpkinStealController] HumanoidRootPart missing"
		)


		return

	end


	--==================================================
	-- ATTACHMENT ON PLAYER
	--==================================================

	stealGuidePlayerAttachment =
		Instance.new(
			"Attachment"
		)


	stealGuidePlayerAttachment.Name =
		"PumpkinStealPlayerAttachment"


	-- Position it slightly below the character
	-- so the beam does not run directly through
	-- the player's torso.

	stealGuidePlayerAttachment.Position =
		Vector3.new(
			0,
			-2,
			0
		)


	stealGuidePlayerAttachment.Parent =
		humanoidRootPart


	--==================================================
	-- ATTACHMENT ON FRONT FENCE
	--==================================================

	stealGuideTargetAttachment =
		Instance.new(
			"Attachment"
		)


	stealGuideTargetAttachment.Name =
		"PumpkinStealTargetAttachment"


	-- Slightly above the center of the fence.

	stealGuideTargetAttachment.Position =
		Vector3.new(
			0,
			2,
			0
		)


	stealGuideTargetAttachment.Parent =
		frontFencePart


	--==================================================
	-- CREATE FOLLOW BEAM
	--==================================================

	stealGuideBeam =
		Instance.new(
			"Beam"
		)


	stealGuideBeam.Name =
		"PumpkinStealGuideBeam"


	stealGuideBeam.Attachment0 =
		stealGuidePlayerAttachment


	stealGuideBeam.Attachment1 =
		stealGuideTargetAttachment


	-- Makes the texture face the player's camera.

	stealGuideBeam.FaceCamera =
		true


	-- Beam thickness.

	stealGuideBeam.Width0 =
		4


	stealGuideBeam.Width1 =
		4


	stealGuideBeam.LightEmission =
		1


	--==================================================
	-- ARROW TEXTURE
	--==================================================

	-- Texture supplied in your example code.

	stealGuideBeam.Texture =
		"rbxassetid://16848361091"


	-- Controls how frequently the arrow texture repeats.

	stealGuideBeam.TextureLength =
		5


	-- Controls movement of the arrow texture.
	--
	-- If the arrows visually move from the base
	-- toward the player instead of toward the base,
	-- change this from 1 to -1.

	stealGuideBeam.TextureSpeed =
		1


	stealGuideBeam.Transparency =
		NumberSequence.new(
			0
		)


	stealGuideBeam.Color =
		ColorSequence.new(
			Color3.fromRGB(
				255,
				255,
				255
			)
		)


	-- Because this is created by a LocalScript,
	-- only THIS player sees the follow arrow.

	stealGuideBeam.Parent =
		character


	print(
		"[PumpkinStealController] Follow arrow created to:",
		frontFencePart:GetFullName()
	)

end


--==================================================
-- WATCH FOR NEW STEAL PROMPTS
--==================================================

Plots.DescendantAdded:Connect(
	function(descendant)

		if IsStealPrompt(
			descendant
			) then

			task.defer(
				function()

					ConnectStealPrompt(
						descendant
					)

				end
			)

		end

	end
)


--==================================================
-- STEAL STATE CHANGED
--==================================================

StealStateChanged.OnClientEvent:Connect(
	function(
		isStealing,
		info
	)

		print(
			"[PumpkinStealController] StealStateChanged:",
			isStealing,
			info
		)


		currentlyStealing =
			isStealing == true


		--==================================================
		-- START STEALING
		--==================================================

		if currentlyStealing then

			--==================================================
			-- THEFT ID
			--==================================================

			if info
				and type(
					info.TheftId
				) == "string" then

				activeTheftId =
					info.TheftId


			else

				activeTheftId =
					nil

			end


			--==================================================
			-- THIEF PLOT
			--==================================================

			if info
				and type(
					info.ThiefPlotName
				) == "string" then

				activeThiefPlotName =
					info.ThiefPlotName


			else

				activeThiefPlotName =
					nil

			end


			--==================================================
			-- HIDE OTHER STEAL PROMPTS
			--==================================================

			HideOtherStealPrompts()


			--==================================================
			-- SHOW STEALING UI
			--==================================================

			ShowStealingUI()


			--==================================================
			-- SHOW FOLLOW ARROW
			--==================================================

			if activeThiefPlotName then

				ShowReturnArrow(
					activeThiefPlotName
				)


			else

				warn(
					"[PumpkinStealController] Missing ThiefPlotName"
				)

			end


		else

			--==================================================
			-- STOP STEALING
			--==================================================

			activeTheftId =
				nil


			activeThiefPlotName =
				nil


			HideStealingUI()


			HideReturnArrow()


			RestoreStealPrompts()

		end

	end
)


--==================================================
-- VICTIM: SHOW STOLEN UI
--==================================================

ShowPumpkinStolenUI.OnClientEvent:Connect(
	function(
		theftId,
		thiefName
	)

		print(
			"[PumpkinStealController] ShowPumpkinStolenUI received:",
			theftId,
			thiefName
		)


		ShowVictimStolenUI(
			theftId,
			thiefName
		)

	end
)


--==================================================
-- VICTIM: HIDE STOLEN UI
--==================================================

HidePumpkinStolenUI.OnClientEvent:Connect(
	function(
		theftId
	)

		HideVictimStolenUI(
			theftId
		)

	end
)


--==================================================
-- CHARACTER RESPAWN
--==================================================

player.CharacterAdded:Connect(
	function(character)

		if not currentlyStealing then

			return

		end


		-- Wait for the new character to exist.

		character:WaitForChild(
			"HumanoidRootPart"
		)


		-- Recreate the follow beam if the player
		-- somehow respawns while a theft is active.

		if activeThiefPlotName then

			task.defer(
				function()

					ShowReturnArrow(
						activeThiefPlotName
					)

				end
			)

		end

	end
)


--==================================================
-- INITIALIZE EXISTING PROMPTS
--==================================================

ConnectAllStealPrompts()


--==================================================
-- STARTED
--==================================================

print(
	"[PumpkinStealController] Started for",
	player.Name
)
