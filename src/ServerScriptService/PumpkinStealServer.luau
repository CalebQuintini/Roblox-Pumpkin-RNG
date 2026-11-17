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


local RunService =
	game:GetService(
		"RunService"
	)


local ServerScriptService =
	game:GetService(
		"ServerScriptService"
	)


--==================================================
-- MODULES
--==================================================

local PlotService =
	require(
		script.Parent:WaitForChild(
			"PlotService"
		)
	)


local PlayerDataService =
	require(
		script.Parent:WaitForChild(
			"PlayerDataService"
		)
	)


local PumpkinStealService =
	require(
		script.Parent:WaitForChild(
			"PumpkinStealService"
		)
	)


local PumpkinInventoryService =
	require(
		script.Parent:WaitForChild(
			"PumpkinInventoryService"
		)
	)


local PumpkinPurseAdapter =
	require(
		script.Parent:WaitForChild(
			"PumpkinPurseAdapter"
		)
	)


local CurrencyService =
	require(
		script.Parent:WaitForChild(
			"CurrencyService"
		)
	)


local PlayerFeedbackService =
	require(
		script.Parent:WaitForChild(
			"PlayerFeedbackService"
		)
	)


--==================================================
-- WORLD REFERENCES
--==================================================

local Plots =
	workspace:WaitForChild(
		"Plots"
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage:WaitForChild(
		"Remotes"
	)


--==================================================
-- GET / CREATE STEAL REMOTE FOLDER
--==================================================

local StealRemotes =
	Remotes:FindFirstChild(
		"PumpkinSteal"
	)


if not StealRemotes then

	StealRemotes =
		Instance.new(
			"Folder"
		)


	StealRemotes.Name =
		"PumpkinSteal"


	StealRemotes.Parent =
		Remotes

end


--==================================================
-- GET / CREATE REMOTE EVENT
--==================================================

local function GetOrCreateRemoteEvent(
	name
)

	local remote =
		StealRemotes:FindFirstChild(
			name
		)


	if remote
		and remote:IsA(
			"RemoteEvent"
		) then

		return remote

	end


	if remote then

		remote:Destroy()

	end


	remote =
		Instance.new(
			"RemoteEvent"
		)


	remote.Name =
		name


	remote.Parent =
		StealRemotes


	return remote

end


--==================================================
-- REMOTE REFERENCES
--==================================================

local StealStateChanged =
	GetOrCreateRemoteEvent(
		"StealStateChanged"
	)


local ShowPumpkinStolenUI =
	GetOrCreateRemoteEvent(
		"ShowPumpkinStolenUI"
	)


local HidePumpkinStolenUI =
	GetOrCreateRemoteEvent(
		"HidePumpkinStolenUI"
	)


--==================================================
-- BASEBALL BAT CANCEL EVENT
--==================================================

local CancelPumpkinSteal =
	ServerScriptService:FindFirstChild(
		"CancelPumpkinSteal"
	)


if not CancelPumpkinSteal then

	CancelPumpkinSteal =
		Instance.new(
			"BindableEvent"
		)


	CancelPumpkinSteal.Name =
		"CancelPumpkinSteal"


	CancelPumpkinSteal.Parent =
		ServerScriptService

end


--==================================================
-- TOOLBOX SANDBOX COMPATIBILITY
--==================================================

-- Baseball Bat R15 came from the Toolbox.
--
-- Its KnifeScript is sandboxed, so this event
-- also needs to allow sandboxed scripts to fire it.

CancelPumpkinSteal.Sandboxed =
	true


--==================================================
-- SETTINGS
--==================================================

local STEAL_HOLD_DURATION =
	0.5


local STEAL_DISTANCE =
	10


local RETURN_CHECK_INTERVAL =
	0.1


local RETURN_EXTRA_DISTANCE =
	3


-- Exact name of the new bat Tool.

local BASEBALL_BAT_NAME =
	"Baseball Bat R15"


--==================================================
-- RUNTIME DATA
--==================================================

-- [PumpkinModel] = ProximityPrompt

local pumpkinPrompts =
	{}


-- [Plot] = FrontFencePart

local stealReturnPoints =
	{}


local returnCheckTimer =
	0


--==================================================
-- FIND PLAYER BY USER ID
--==================================================

local function FindPlayerByUserId(
	userId
)

	for _, player in ipairs(
		Players:GetPlayers()
		) do

		if player.UserId
			== userId then

			return player

		end

	end


	return nil

end


--==================================================
-- FIND BASEBALL BAT
--==================================================

local function FindBaseballBat(
	player
)

	if not player then

		return nil

	end


	--==================================================
	-- CHECK CHARACTER FIRST
	--==================================================

	-- If the Tool is currently equipped,
	-- Roblox parents it to the Character.

	local character =
		player.Character


	if character then

		local bat =
			character:FindFirstChild(
				BASEBALL_BAT_NAME
			)


		if bat
			and bat:IsA(
				"Tool"
			) then

			return bat

		end

	end


	--==================================================
	-- CHECK BACKPACK
	--==================================================

	local backpack =
		player:FindFirstChild(
			"Backpack"
		)


	if backpack then

		local bat =
			backpack:FindFirstChild(
				BASEBALL_BAT_NAME
			)


		if bat
			and bat:IsA(
				"Tool"
			) then

			return bat

		end

	end


	return nil

end


--==================================================
-- SET PLAYER STEALING STATE
--==================================================

local function SetPlayerStealingState(
	player,
	isStealing
)

	if not player then

		return

	end


	--==================================================
	-- ATTRIBUTE
	--==================================================

	-- KnifeScript will also check this as a
	-- second layer of protection.

	player:SetAttribute(
		"IsStealingPumpkin",
		isStealing
	)


	--==================================================
	-- STEAL START
	--==================================================

	if isStealing then

		--==================================================
		-- UNEQUIP CURRENT TOOLS
		--==================================================

		-- If the player currently has the baseball bat
		-- selected, force them out of it immediately.

		local character =
			player.Character


		if character then

			local humanoid =
				character:FindFirstChildOfClass(
					"Humanoid"
				)


			if humanoid then

				humanoid:UnequipTools()

			end

		end


		-- Give Roblox a moment to move the equipped
		-- Tool back into Backpack.

		task.defer(
			function()

				if not player.Parent then

					return

				end


				local bat =
					FindBaseballBat(
						player
					)


				if bat then

					bat.Enabled =
						false

				end

			end
		)


		return

	end


	--==================================================
	-- STEAL END
	--==================================================

	-- Theft either succeeded or was cancelled.
	--
	-- Give the player access to the bat again.

	local bat =
		FindBaseballBat(
			player
		)


	if bat then

		bat.Enabled =
			true

	end

end


--==================================================
-- FIND PLACED PUMPKIN RECORD
--==================================================

local function FindPlacedRecord(
	data,
	instanceId
)

	if not data then

		return nil,
			nil

	end


	if type(
		data.PlacedPumpkins
		) ~= "table" then

		return nil,
			nil

	end


	for index, record in ipairs(
		data.PlacedPumpkins
		) do

		if record.InstanceId
			== instanceId then

			return record,
				index

		end

	end


	return nil,
		nil

end


--==================================================
-- GET PUMPKIN OWNER
--==================================================

local function GetPumpkinOwner(
	pumpkinModel
)

	if not pumpkinModel then

		return nil

	end


	local ownerUserId =
		pumpkinModel:GetAttribute(
			"OwnerUserId"
		)


	if type(ownerUserId)
		~= "number" then

		return nil

	end


	if ownerUserId
		== 0 then

		return nil

	end


	return FindPlayerByUserId(
		ownerUserId
	)

end


--==================================================
-- FIND PROMPT PART
--==================================================

local function FindPromptPart(
	pumpkinModel
)

	if not pumpkinModel then

		return nil

	end


	if pumpkinModel.PrimaryPart then

		return pumpkinModel.PrimaryPart

	end


	return pumpkinModel:FindFirstChildWhichIsA(
		"BasePart",
		true
	)

end


--==================================================
-- UPDATE ONE STEAL PROMPT
--==================================================

local function UpdatePrompt(
	pumpkinModel
)

	local prompt = pumpkinPrompts[pumpkinModel]


	if not prompt then

		return

	end


	if not prompt.Parent then

		pumpkinPrompts[pumpkinModel] = nil


		return

	end


	if not pumpkinModel
		or not pumpkinModel.Parent then

		prompt.Enabled =
			false


		return

	end


	local instanceId =
		pumpkinModel:GetAttribute(
			"InstanceId"
		)


	if type(instanceId)
		~= "string"
		or instanceId == "" then

		prompt.Enabled =
			false


		return

	end


	if PumpkinStealService.IsPumpkinReserved(
		instanceId
		) then

		prompt.Enabled =
			false


		return

	end


	prompt.Enabled =
		true

end


--==================================================
-- HIDE THEFT UI
--==================================================

local function HideTheftUI(
	reservation
)

	if not reservation then

		return

	end


	--==================================================
	-- THIEF UI
	--==================================================

	local thief =
		reservation.Thief


	if thief
		and thief.Parent
		== Players then

		StealStateChanged:FireClient(
			thief,
			false
		)

	end


	--==================================================
	-- VICTIM UI
	--==================================================

	local victim =
		reservation.Victim


	if victim
		and victim.Parent
		== Players then

		HidePumpkinStolenUI:FireClient(
			victim,
			reservation.TheftId
		)

	end

end


--==================================================
-- CANCEL THEFT
--==================================================

local function CancelTheft(
	thief,
	reason
)

	if not thief then

		return false

	end


	local reservation =
		PumpkinStealService.GetActiveTheft(
			thief
		)


	if not reservation then

		-- Safety:
		-- make sure stealing restrictions are cleared.

		SetPlayerStealingState(
			thief,
			false
		)


		return false

	end


	--==================================================
	-- REMOVE UI / BEAM
	--==================================================

	HideTheftUI(
		reservation
	)


	--==================================================
	-- RELEASE RESERVED PUMPKIN
	--==================================================

	local instanceId =
		reservation.InstanceId


	local releaseSuccess,
		releaseResult =
		PumpkinStealService.ReleasePumpkin(
			instanceId
		)


	if not releaseSuccess then

		warn(
			"[PumpkinStealServer] Could not release pumpkin:",
			releaseResult
		)

	end


	--==================================================
	-- REMOVE STEALING RESTRICTIONS
	--==================================================

	SetPlayerStealingState(
		thief,
		false
	)


	--==================================================
	-- RESTORE STEAL PROMPT
	--==================================================

	local pumpkinModel =
		reservation.PumpkinModel


	if pumpkinModel
		and pumpkinModel.Parent then

		UpdatePrompt(
			pumpkinModel
		)

	end


	print(
		"[PumpkinStealServer]",
		thief.Name,
		"theft cancelled.",
		"Reason:",
		reason
			or "Unknown",
		"InstanceId:",
		instanceId
	)


	return true

end


--==================================================
-- COMPLETE THEFT
--==================================================

local function CompleteTheft(
	thief
)

	if not thief then

		return

	end


	local reservation =
		PumpkinStealService.GetActiveTheft(
			thief
		)


	if not reservation then

		return

	end


	--==================================================
	-- PREVENT DOUBLE COMPLETION
	--==================================================

	if reservation.Completing then

		return

	end


	reservation.Completing =
		true


	--==================================================
	-- VICTIM
	--==================================================

	local victim =
		reservation.Victim


	if not victim
		or victim.Parent
		~= Players then

		reservation.Completing =
			false


		CancelTheft(
			thief,
			"VictimLeft"
		)


		return

	end


	--==================================================
	-- PLAYER DATA
	--==================================================

	local victimData =
		PlayerDataService.GetData(
			victim
		)


	local thiefData =
		PlayerDataService.GetData(
			thief
		)


	if not victimData
		or not thiefData then

		reservation.Completing =
			false


		CancelTheft(
			thief,
			"DataNotLoaded"
		)


		return

	end


	--==================================================
	-- INVENTORY CAPACITY
	--==================================================

	if not PumpkinInventoryService.HasInventorySpace(
		thief
		) then

		reservation.Completing =
			false


		CancelTheft(
			thief,
			"InventoryFull"
		)


		return

	end


	--==================================================
	-- FIND VICTIM'S PLACED RECORD
	--==================================================

	local instanceId =
		reservation.InstanceId


	local record,
		recordIndex =
		FindPlacedRecord(
			victimData,
			instanceId
		)


	if not record
		or not recordIndex then

		reservation.Completing =
			false


		CancelTheft(
			thief,
			"PlacedRecordMissing"
		)


		return

	end


	--==================================================
	-- VERIFY INSTANCE
	--==================================================

	if record.InstanceId
		~= instanceId then

		reservation.Completing =
			false


		CancelTheft(
			thief,
			"InstanceIdMismatch"
		)


		return

	end


	--==================================================
	-- PUMPKIN ID
	--==================================================

	local pumpkinId =
		record.PumpkinId


	if type(pumpkinId)
		~= "string"
		or pumpkinId == "" then

		reservation.Completing =
			false


		CancelTheft(
			thief,
			"InvalidPumpkinId"
		)


		return

	end


	--==================================================
	-- PAY VICTIM STORED MONEY
	--==================================================

	local storedMoney =
		tonumber(
			record.StoredMoney
		)
		or 0


	if storedMoney > 0 then

		CurrencyService.AddDollars(
			victim,
			storedMoney
		)


		record.StoredMoney =
			0

	end


	--==================================================
	-- TRANSFER SAME PUMPKIN TO THIEF
	--==================================================

	local addSuccess,
		addResult =
		PumpkinInventoryService.AddExistingPumpkin(
			thief,
			pumpkinId,
			instanceId
		)


	if not addSuccess then

		reservation.Completing =
			false


		CancelTheft(
			thief,
			addResult
				or "InventoryAddFailed"
		)


		return

	end


	--==================================================
	-- REMOVE VICTIM RECORD
	--==================================================

	table.remove(
		victimData.PlacedPumpkins,
		recordIndex
	)


	--==================================================
	-- DESTROY WORLD PUMPKIN
	--==================================================

	local pumpkinModel =
		reservation.PumpkinModel


	if pumpkinModel
		and pumpkinModel.Parent then

		pumpkinModel:Destroy()

	end


	--==================================================
	-- REFRESH THIEF PURSE
	--==================================================

	PumpkinPurseAdapter.RefreshPlayer(
		thief
	)


	--==================================================
	-- HIDE STEAL UI
	--==================================================

	HideTheftUI(
		reservation
	)


	--==================================================
	-- RELEASE SERVICE RESERVATION
	--==================================================

	PumpkinStealService.ReleasePumpkin(
		instanceId
	)


	--==================================================
	-- RESTORE BASEBALL BAT
	--==================================================

	SetPlayerStealingState(
		thief,
		false
	)


	--==================================================
	-- SUCCESS FEEDBACK
	--==================================================

	PlayerFeedbackService.Send(
		thief,
		"BarrierSuccessfullyActivated"
	)


	print(
		"[PumpkinStealServer]",
		thief.Name,
		"SUCCESSFULLY STOLE",
		pumpkinId,
		"from",
		victim.Name,
		"InstanceId:",
		instanceId
	)

end


--==================================================
-- START THEFT
--==================================================

local function StartTheft(
	thief,
	pumpkinModel
)

	if not thief
		or not pumpkinModel then

		return

	end


	--==================================================
	-- BLOCK STEALING DURING TUTORIAL
	--==================================================

	-- TutorialService sets this Attribute while the
	-- player is still completing the tutorial.
	--
	-- This check is server-side so the player cannot
	-- bypass the tutorial restriction by triggering
	-- the ProximityPrompt another way.

	if thief:GetAttribute(
		"TutorialActive"
		) then

		return

	end


	--==================================================
	-- ALREADY STEALING
	--==================================================

	if PumpkinStealService.IsStealing(
		thief
		) then

		return

	end


	--==================================================
	-- VICTIM
	--==================================================

	local victim =
		GetPumpkinOwner(
			pumpkinModel
		)


	if not victim then

		return

	end


	if victim
		== thief then

		return

	end


	--==================================================
	-- INSTANCE ID
	--==================================================

	local instanceId =
		pumpkinModel:GetAttribute(
			"InstanceId"
		)


	if type(instanceId)
		~= "string"
		or instanceId == "" then

		return

	end


	--==================================================
	-- ALREADY RESERVED
	--==================================================

	if PumpkinStealService.IsPumpkinReserved(
		instanceId
		) then

		return

	end


	--==================================================
	-- INVENTORY SPACE
	--==================================================

	if not PumpkinInventoryService.HasInventorySpace(
		thief
		) then

		return

	end


	--==================================================
	-- VICTIM PLOT
	--==================================================

	local victimPlot =
		PlotService.GetPlayerPlot(
			victim
		)


	if not victimPlot then

		warn(
			"[PumpkinStealServer] Could not find victim plot for",
			victim.Name
		)


		return

	end


	--==================================================
	-- THIEF PLOT
	--==================================================

	local thiefPlot =
		PlotService.GetPlayerPlot(
			thief
		)


	if not thiefPlot then

		warn(
			"[PumpkinStealServer] Could not find thief plot for",
			thief.Name
		)


		return

	end


	--==================================================
	-- RESERVE PUMPKIN
	--==================================================

	-- ReservePumpkin returns:
	--
	-- success
	-- reservation
	-- reason

	local reserveSuccess,
		reservation,
		reserveReason =
		PumpkinStealService.ReservePumpkin(
			thief,
			victim,
			pumpkinModel,
			victimPlot,
			thiefPlot
		)


	if not reserveSuccess then

		warn(
			"[PumpkinStealServer] Could not reserve pumpkin:",
			reserveReason
		)


		return

	end


	if type(reservation)
		~= "table" then

		warn(
			"[PumpkinStealServer] ReservePumpkin succeeded",
			"but returned an invalid reservation."
		)


		return

	end


	--==================================================
	-- ENTER STEAL MODE
	--==================================================

	-- This:
	--
	-- 1. sets IsStealingPumpkin = true
	-- 2. unequips the baseball bat
	-- 3. disables the baseball bat

	SetPlayerStealingState(
		thief,
		true
	)


	--==================================================
	-- DISABLE STEAL PROMPT
	--==================================================

	UpdatePrompt(
		pumpkinModel
	)


	--==================================================
	-- THIEF UI / BEAM
	--==================================================

	StealStateChanged:FireClient(
		thief,
		true,
		{

			TheftId =
				reservation.TheftId,

			InstanceId =
				reservation.InstanceId,

			PumpkinId =
				reservation.PumpkinId,

			VictimUserId =
				victim.UserId,

			VictimName =
				victim.Name,

			ThiefPlotName =
				thiefPlot.Name,
		}
	)


	--==================================================
	-- VICTIM UI
	--==================================================

	ShowPumpkinStolenUI:FireClient(
		victim,
		reservation.TheftId,
		thief.Name
	)


	--==================================================
	-- VICTIM SOUND
	--==================================================

	PlayerFeedbackService.Send(
		victim,
		"PlayerBaseUnlocked"
	)


	print(
		"[PumpkinStealServer]",
		thief.Name,
		"started stealing",
		reservation.PumpkinId,
		"from",
		victim.Name,
		"TheftId:",
		reservation.TheftId
	)

end


--==================================================
-- SETUP ONE PUMPKIN
--==================================================

local function SetupPumpkin(
	pumpkinModel
)

	if not pumpkinModel
		or not pumpkinModel:IsA(
			"Model"
		) then

		return

	end


	local instanceId =
		pumpkinModel:GetAttribute(
			"InstanceId"
		)


	if type(instanceId)
		~= "string"
		or instanceId == "" then

		return

	end


	--==================================================
	-- ALREADY SET UP
	--==================================================

	if pumpkinPrompts[
		pumpkinModel
		] then

		UpdatePrompt(
			pumpkinModel
		)


		return

	end


	local promptPart =
		FindPromptPart(
			pumpkinModel
		)


	if not promptPart then

		return

	end


	--==================================================
	-- FIND / CREATE PROMPT
	--==================================================

	local prompt =
		promptPart:FindFirstChild(
			"StealPumpkinPrompt"
		)


	if not prompt then

		prompt =
			Instance.new(
				"ProximityPrompt"
			)


		prompt.Name =
			"StealPumpkinPrompt"


		prompt.Parent =
			promptPart

	end


	prompt.ActionText =
		"Steal"


	prompt.ObjectText =
		"Pumpkin"


	prompt.HoldDuration =
		STEAL_HOLD_DURATION


	prompt.MaxActivationDistance =
		STEAL_DISTANCE


	prompt.RequiresLineOfSight =
		false


	pumpkinPrompts[pumpkinModel] = prompt


	--==================================================
	-- TRIGGERED
	--==================================================

	prompt.Triggered:Connect(
		function(player)

			StartTheft(
				player,
				pumpkinModel
			)

		end
	)


	--==================================================
	-- CLEANUP
	--==================================================

	pumpkinModel.Destroying:Connect(
		function()

			pumpkinPrompts[pumpkinModel] = nil

		end
	)


	UpdatePrompt(
		pumpkinModel
	)

end


--==================================================
-- REGISTER RETURN POINT
--==================================================

local function CreateStealReturnTrigger(
	plot
)

	if not plot then

		return

	end


	local normalBarrier =
		plot:FindFirstChild(
			"NormalBarrier"
		)


	if not normalBarrier then

		warn(
			"[PumpkinStealServer]",
			plot.Name,
			"is missing NormalBarrier."
		)


		return

	end


	local barrierModel =
		normalBarrier:FindFirstChild(
			"BarrierModel"
		)


	if not barrierModel then

		warn(
			"[PumpkinStealServer]",
			plot.Name,
			"is missing NormalBarrier.BarrierModel."
		)


		return

	end


	local frontFencePart =
		barrierModel:FindFirstChild(
			"FrontFencePart",
			true
		)


	if not frontFencePart
		or not frontFencePart:IsA(
			"BasePart"
		) then

		warn(
			"[PumpkinStealServer]",
			plot.Name,
			"is missing FrontFencePart."
		)


		return

	end


	--==================================================
	-- REMOVE OLD GENERATED TRIGGER
	--==================================================

	local oldTrigger =
		plot:FindFirstChild(
			"StealReturnTrigger"
		)


	if oldTrigger then

		oldTrigger:Destroy()

	end


	--==================================================
	-- USE REAL FRONT FENCE
	--==================================================

	stealReturnPoints[plot] = frontFencePart


	print(
		"[PumpkinStealServer] Registered return point:",
		frontFencePart:GetFullName()
	)

end


--==================================================
-- CHECK PLAYER AT RETURN POINT
--==================================================

local function IsPlayerAtReturnPoint(
	player,
	frontFencePart
)

	if not player
		or not frontFencePart
		or not frontFencePart.Parent then

		return false

	end


	local character =
		player.Character


	if not character then

		return false

	end


	local rootPart =
		character:FindFirstChild(
			"HumanoidRootPart"
		)


	if not rootPart then

		return false

	end


	local localPosition =
		frontFencePart.CFrame
		:PointToObjectSpace(
			rootPart.Position
		)


	local halfSize =
		frontFencePart.Size
		* 0.5


	local insideX =
		math.abs(
			localPosition.X
		)
		<=
		halfSize.X
		+
		RETURN_EXTRA_DISTANCE


	local insideY =
		math.abs(
			localPosition.Y
		)
		<=
		halfSize.Y
		+
		RETURN_EXTRA_DISTANCE


	local insideZ =
		math.abs(
			localPosition.Z
		)
		<=
		halfSize.Z
		+
		RETURN_EXTRA_DISTANCE


	return insideX
		and insideY
		and insideZ

end


--==================================================
-- SETUP EXISTING PLOTS
--==================================================

for _, plot in ipairs(
	Plots:GetChildren()
	) do

	if plot:IsA(
		"Model"
		)
			or plot:IsA(
				"Folder"
			) then

		CreateStealReturnTrigger(
			plot
		)

	end

end


--==================================================
-- SETUP FUTURE PLOTS
--==================================================

Plots.ChildAdded:Connect(
	function(plot)

		if not plot:IsA(
			"Model"
			)
				and not plot:IsA(
					"Folder"
				) then

			return

		end


		task.defer(
			function()

				CreateStealReturnTrigger(
					plot
				)

			end
		)

	end
)


--==================================================
-- SETUP EXISTING PUMPKINS
--==================================================

for _, descendant in ipairs(
	Plots:GetDescendants()
	) do

	if descendant:IsA(
		"Model"
		)
			and descendant:GetAttribute(
				"InstanceId"
			) then

		SetupPumpkin(
			descendant
		)

	end

end


--==================================================
-- SETUP FUTURE PUMPKINS
--==================================================

Plots.DescendantAdded:Connect(
	function(descendant)

		if not descendant:IsA(
			"Model"
			) then

			return

		end


		task.defer(
			function()

				local instanceId =
					descendant:GetAttribute(
						"InstanceId"
					)


				if instanceId then

					SetupPumpkin(
						descendant
					)

				end

			end
		)

	end
)


--==================================================
-- RETURN-TO-BASE CHECK
--==================================================

RunService.Heartbeat:Connect(
	function(deltaTime)

		returnCheckTimer +=
			deltaTime


		if returnCheckTimer
			< RETURN_CHECK_INTERVAL then

			return

		end


		returnCheckTimer =
			0


		for _, player in ipairs(
			Players:GetPlayers()
			) do

			local reservation =
				PumpkinStealService.GetActiveTheft(
					player
				)


			if reservation
				and not reservation.Completing then

				local thiefPlot =
					reservation.ThiefPlot


				local frontFencePart = stealReturnPoints[thiefPlot]


				if frontFencePart
					and IsPlayerAtReturnPoint(
						player,
						frontFencePart
					) then

					CompleteTheft(
						player
					)

				end

			end

		end

	end
)


--==================================================
-- BASEBALL BAT CANCEL HANDLER
--==================================================

CancelPumpkinSteal.Event:Connect(
	function(
		targetPlayer,
		reason
	)

		if not targetPlayer then

			return

		end


		if not targetPlayer:IsA(
			"Player"
			) then

			return

		end


		if not PumpkinStealService.IsStealing(
			targetPlayer
			) then

			return

		end


		print(
			"[PumpkinStealServer]",
			targetPlayer.Name,
			"was hit while stealing."
		)


		CancelTheft(
			targetPlayer,
			reason
				or "HitByBaseballBat"
		)

	end
)


--==================================================
-- PLAYER ADDED
--==================================================

Players.PlayerAdded:Connect(
	function(player)

		-- Make sure stale attributes never carry
		-- into a new server session.

		player:SetAttribute(
			"IsStealingPumpkin",
			false
		)

	end
)


--==================================================
-- EXISTING PLAYERS
--==================================================

for _, player in ipairs(
	Players:GetPlayers()
	) do

	if not PumpkinStealService.IsStealing(
		player
		) then

		player:SetAttribute(
			"IsStealingPumpkin",
			false
		)

	end

end


--==================================================
-- PLAYER REMOVING
--==================================================

Players.PlayerRemoving:Connect(
	function(leavingPlayer)

		--==================================================
		-- LEAVING PLAYER IS THIEF
		--==================================================

		if PumpkinStealService.IsStealing(
			leavingPlayer
			) then

			CancelTheft(
				leavingPlayer,
				"ThiefLeft"
			)

		end


		--==================================================
		-- LEAVING PLAYER MAY BE VICTIM
		--==================================================

		for _, possibleThief in ipairs(
			Players:GetPlayers()
			) do

			if possibleThief
				~= leavingPlayer then

				local reservation =
					PumpkinStealService.GetActiveTheft(
						possibleThief
					)


				if reservation
					and reservation.Victim
					== leavingPlayer then

					CancelTheft(
						possibleThief,
						"VictimLeft"
					)

				end

			end

		end

	end
)


--==================================================
-- STARTED
--==================================================

print(
	"[PumpkinStealServer] Started"
)
