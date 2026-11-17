--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

local RunService =
	game:GetService("RunService")

local PhysicsService =
	game:GetService("PhysicsService")


--==================================================
-- MODULES
--==================================================

local PlayerDataService =
	require(
		script.Parent
		:WaitForChild("PlayerDataService")
	)

local PlotService =
	require(
		script.Parent
		:WaitForChild("PlotService")
	)

local GameConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("GameConfig")
	)


--==================================================
-- MODULE
--==================================================

local BarrierService = {}


--==================================================
-- BASE LOCK CONFIG
--==================================================

local BaseLockConfig =
	GameConfig.BaseLock
	or {}


--==================================================
-- SETTINGS
--==================================================

local NORMAL_DURATION =
	BaseLockConfig.NormalDuration
	or 60


local PREMIUM_DURATION =
	BaseLockConfig.PremiumDuration
	or (10 * 60)


local FORCED_UNLOCK_DURATION =
	BaseLockConfig.ForcedUnlockDuration
	or 20


-- How often we re-check the plot owner's character
-- collision group in live servers.
local OWNER_COLLISION_REFRESH_INTERVAL =
	1

--==================================================
-- STATES
--==================================================

local STATE_UNLOCKED =
	"Unlocked"

local STATE_NORMAL =
	"Normal"

local STATE_PREMIUM =
	"Premium"

local STATE_FORCED_UNLOCKED =
	"ForcedUnlocked"


BarrierService.States = {
	Unlocked = STATE_UNLOCKED,
	Normal = STATE_NORMAL,
	Premium = STATE_PREMIUM,
	ForcedUnlocked = STATE_FORCED_UNLOCKED,
}


--==================================================
-- RUNTIME STATE
--==================================================

-- [plot] = state

local plotStates =
	{}


local heartbeatConnection =
	nil


--==================================================
-- COLLISION GROUP HELPER
--==================================================

local function RegisterCollisionGroup(
	groupName
)

	pcall(
		function()

			PhysicsService:RegisterCollisionGroup(
				groupName
			)

		end
	)

end


--==================================================
-- GET BARRIER FOLDER
--==================================================

local function GetBarrierFolder(
	plot,
	name
)

	return plot:FindFirstChild(
		name
	)

end


--==================================================
-- GET BARRIER MODEL
--==================================================

local function GetBarrierModel(
	plot,
	folderName
)

	local folder =
		GetBarrierFolder(
			plot,
			folderName
		)

	if not folder then

		return nil

	end

	return folder:FindFirstChild(
		"BarrierModel"
	)

end


--==================================================
-- GET BILLBOARDS
--==================================================

local function GetTimerBillboards(
	model
)

	local result =
		{}

	if not model then

		return result

	end

	local front =
		model:FindFirstChild(
			"FrontTimeBillboardGui",
			true
		)

	local back =
		model:FindFirstChild(
			"BackTimeBillboardGui",
			true
		)

	if front
		and front:IsA("BillboardGui") then

		table.insert(
			result,
			front
		)

	end

	if back
		and back:IsA("BillboardGui") then

		table.insert(
			result,
			back
		)

	end

	return result

end


--==================================================
-- FIND TEXT LABEL
--==================================================

local function FindTextLabel(
	billboard
)

	if not billboard then

		return nil

	end

	for _, descendant in ipairs(
		billboard:GetDescendants()
		) do

		if descendant:IsA(
			"TextLabel"
			) then

			return descendant

		end

	end

	return nil

end


--==================================================
-- FORMAT TIME
--==================================================

local function FormatTime(
	seconds,
	mode
)

	seconds =
		math.max(
			0,
			math.ceil(seconds)
		)

	-- Normal:
	-- 60
	-- 59
	-- 58...

	if mode == STATE_NORMAL then

		return tostring(
			seconds
		)

	end

	-- Premium:
	-- 10:00
	-- 9:59
	-- ...

	local minutes =
		math.floor(
			seconds / 60
		)

	local remainingSeconds =
		seconds % 60

	return string.format(
		"%d:%02d",
		minutes,
		remainingSeconds
	)

end


--==================================================
-- UPDATE BILLBOARDS
--==================================================

local function SetBillboards(
	billboards,
	enabled,
	seconds,
	mode
)

	for _, billboard in ipairs(
		billboards
		) do

		billboard.Enabled =
			enabled

		local label =
			FindTextLabel(
				billboard
			)

		if label then

			label.Text =
				FormatTime(
					seconds or 0,
					mode
				)

		end

	end

end


--==================================================
-- SAVE ORIGINAL BARRIER PART STATE
--==================================================

local function SaveOriginalPartStates(
	state,
	model
)

	if not model then

		return

	end

	for _, descendant in ipairs(
		model:GetDescendants()
		) do

		if descendant:IsA(
			"BasePart"
			) then

			if not state.OriginalParts[
				descendant
				] then

				state.OriginalParts[descendant
				] = {
					Transparency =
						descendant.Transparency,

					CanCollide =
						descendant.CanCollide,

					CanTouch =
						descendant.CanTouch,

					CanQuery =
						descendant.CanQuery,
				}

			end

		end

	end

end


--==================================================
-- SET BARRIER MODEL ACTIVE
--==================================================

local function SetBarrierVisible(
	state,
	model,
	visible
)

	if not model then

		return

	end

	for _, descendant in ipairs(
		model:GetDescendants()
		) do

		if descendant:IsA(
			"BasePart"
			) then

			local original = state.OriginalParts[descendant]

			if visible then

				if original then

					descendant.Transparency =
						original.Transparency

					descendant.CanCollide =
						original.CanCollide

					descendant.CanTouch =
						original.CanTouch

					descendant.CanQuery =
						original.CanQuery

				else

					descendant.Transparency =
						0

					descendant.CanCollide =
						true

				end

			else

				descendant.Transparency =
					1

				descendant.CanCollide =
					false

				descendant.CanTouch =
					false

				descendant.CanQuery =
					false

			end

		end

	end

end


--==================================================
-- SET BARRIER COLLISION GROUP
--==================================================

local function ApplyBarrierCollisionGroup(
	state,
	model
)

	if not model then

		return

	end

	for _, descendant in ipairs(
		model:GetDescendants()
		) do

		if descendant:IsA(
			"BasePart"
			) then

			descendant.CollisionGroup =
				state.BarrierCollisionGroup

		end

	end

end


--==================================================
-- SET CHARACTER COLLISION GROUP
--==================================================

local function SetCharacterCollisionGroup(
	character,
	groupName
)

	if not character then

		return

	end

	for _, descendant in ipairs(
		character:GetDescendants()
		) do

		if descendant:IsA(
			"BasePart"
			) then

			descendant.CollisionGroup =
				groupName

		end

	end

end


--==================================================
-- APPLY OWNER COLLISION GROUP
--==================================================

local function ApplyOwnerCharacterCollision(
	state,
	character
)

	if not state
		or not character then

		return

	end


	SetCharacterCollisionGroup(
		character,
		state.OwnerCollisionGroup
	)

end


--==================================================
-- DISCONNECT OWNER CHARACTER PART WATCHER
--==================================================

local function DisconnectCharacterDescendantConnection(
	state
)

	if not state then

		return

	end


	if state.CharacterDescendantConnection then

		state.CharacterDescendantConnection:Disconnect()

		state.CharacterDescendantConnection =
			nil

	end

end


--==================================================
-- BIND ONE OWNER CHARACTER
--==================================================

local function BindOwnerCharacter(
	state,
	character
)

	if not state
		or not character then

		return

	end


	DisconnectCharacterDescendantConnection(
		state
	)


	ApplyOwnerCharacterCollision(
		state,
		character
	)


	state.CharacterDescendantConnection =
		character.DescendantAdded:Connect(
			function(descendant)

				if descendant:IsA(
					"BasePart"
					) then

					descendant.CollisionGroup = state.OwnerCollisionGroup

				end

			end
		)


	for _, delayTime in ipairs({
		0.1,
		0.5,
		1.5,
		}) do

		task.delay(
			delayTime,

			function()

				if state.OwnerPlayer
					and state.OwnerPlayer.Character == character
					and character.Parent then

					ApplyOwnerCharacterCollision(
						state,
						character
					)

				end

			end
		)

	end

end


--==================================================
-- UPDATE PLOT ATTRIBUTES
--==================================================

local function UpdatePlotAttributes(
	state
)

	state.Plot:SetAttribute(
		"BarrierState",
		state.Mode
	)

	local remaining =
		0

	if state.Mode
		== STATE_FORCED_UNLOCKED then

		remaining =
			state.ForcedUnlockRemaining

	else

		remaining =
			state.RemainingTime

	end

	state.Plot:SetAttribute(
		"BarrierRemainingSeconds",
		math.max(
			0,
			math.ceil(
				remaining
			)
		)
	)

end


--==================================================
-- HIDE EVERYTHING
--==================================================

local function HideAllBarriers(
	state
)

	SetBarrierVisible(
		state,
		state.NormalBarrierModel,
		false
	)

	SetBarrierVisible(
		state,
		state.PremiumBarrierModel,
		false
	)

	SetBillboards(
		state.NormalBillboards,
		false,
		0,
		STATE_NORMAL
	)

	SetBillboards(
		state.PremiumBillboards,
		false,
		0,
		STATE_PREMIUM
	)

end


--==================================================
-- SET UNLOCKED
--==================================================

local function SetUnlocked(
	state
)

	state.Mode =
		STATE_UNLOCKED

	state.RemainingTime =
		0

	state.ForcedUnlockRemaining =
		0

	HideAllBarriers(
		state
	)

	UpdatePlotAttributes(
		state
	)

end


--==================================================
-- START NORMAL INTERNAL
--==================================================

local function StartNormalInternal(
	state,
	duration
)

	HideAllBarriers(
		state
	)

	state.Mode =
		STATE_NORMAL

	state.RemainingTime =
		duration

	state.ForcedUnlockRemaining =
		0

	SetBarrierVisible(
		state,
		state.NormalBarrierModel,
		true
	)

	SetBillboards(
		state.NormalBillboards,
		true,
		duration,
		STATE_NORMAL
	)

	UpdatePlotAttributes(
		state
	)

end


--==================================================
-- START PREMIUM INTERNAL
--==================================================

local function StartPremiumInternal(
	state,
	duration
)

	HideAllBarriers(
		state
	)

	state.Mode =
		STATE_PREMIUM

	state.RemainingTime =
		duration

	state.ForcedUnlockRemaining =
		0

	SetBarrierVisible(
		state,
		state.PremiumBarrierModel,
		true
	)

	SetBillboards(
		state.PremiumBillboards,
		true,
		duration,
		STATE_PREMIUM
	)

	UpdatePlotAttributes(
		state
	)

end


--==================================================
-- INITIALIZE PLOT
--==================================================

function BarrierService.InitializePlot(
	plot
)

	if not plot then

		return nil

	end

	if plotStates[
		plot
		] then

		return plotStates[plot]

	end


	--==================================================
	-- FIND MODELS
	--==================================================

	local normalBarrierModel =
		GetBarrierModel(
			plot,
			"NormalBarrier"
		)

	local premiumBarrierModel =
		GetBarrierModel(
			plot,
			"PremiumBarrier"
		)


	if not normalBarrierModel then

		warn(
			"[BarrierService] Missing NormalBarrier/BarrierModel in",
			plot.Name
		)

	end


	if not premiumBarrierModel then

		warn(
			"[BarrierService] Missing PremiumBarrier/BarrierModel in",
			plot.Name
		)

	end


	--==================================================
	-- COLLISION GROUP NAMES
	--==================================================

	local barrierCollisionGroup =
		"Barrier_"
		.. plot.Name

	local ownerCollisionGroup =
		"BarrierOwner_"
		.. plot.Name


	RegisterCollisionGroup(
		barrierCollisionGroup
	)

	RegisterCollisionGroup(
		ownerCollisionGroup
	)


	-- Owner can walk through their own barrier.

	PhysicsService:CollisionGroupSetCollidable(
		barrierCollisionGroup,
		ownerCollisionGroup,
		false
	)


	--==================================================
	-- CREATE STATE
	--==================================================

	local state = {
		Plot =
			plot,

		OwnerPlayer =
			nil,

		Mode =
			STATE_UNLOCKED,

		RemainingTime =
			0,

		ForcedUnlockRemaining =
			0,

		NormalBarrierModel =
			normalBarrierModel,

		PremiumBarrierModel =
			premiumBarrierModel,

		NormalBillboards =
			GetTimerBillboards(
				normalBarrierModel
			),

		PremiumBillboards =
			GetTimerBillboards(
				premiumBarrierModel
			),

		BarrierCollisionGroup =
			barrierCollisionGroup,

		OwnerCollisionGroup =
			ownerCollisionGroup,

		OriginalParts =
			{},

		CharacterConnection =
			nil,

		CharacterDescendantConnection =
			nil,

		CharacterAppearanceConnection =
			nil,

		OwnerCollisionRefreshTimer =
			0,
	}


	plotStates[plot] = state


	--==================================================
	-- SAVE ORIGINAL VISUAL/COLLISION STATE
	--==================================================

	SaveOriginalPartStates(
		state,
		normalBarrierModel
	)

	SaveOriginalPartStates(
		state,
		premiumBarrierModel
	)


	--==================================================
	-- APPLY COLLISION GROUP
	--==================================================

	ApplyBarrierCollisionGroup(
		state,
		normalBarrierModel
	)

	ApplyBarrierCollisionGroup(
		state,
		premiumBarrierModel
	)


	--==================================================
	-- BEGIN UNLOCKED
	--==================================================

	SetUnlocked(
		state
	)


	return state

end


--==================================================
-- GET PLOT STATE
--==================================================

function BarrierService.GetPlotState(
	plot
)

	return plotStates[plot]

end


--==================================================
-- GET PLAYER STATE
--==================================================

function BarrierService.GetPlayerState(
	player
)

	local plot =
		PlotService.GetPlayerPlot(
			player
		)

	if not plot then

		return nil

	end

	return plotStates[plot]

end


--==================================================
-- BIND PLAYER TO PLOT
--==================================================

function BarrierService.BindPlayerToPlot(
	player,
	plot
)

	local state =
		BarrierService.InitializePlot(
			plot
		)


	if not state then

		return false

	end


	if state.CharacterConnection then

		state.CharacterConnection:Disconnect()

		state.CharacterConnection =
			nil

	end


	if state.CharacterAppearanceConnection then

		state.CharacterAppearanceConnection:Disconnect()

		state.CharacterAppearanceConnection =
			nil

	end


	DisconnectCharacterDescendantConnection(
		state
	)


	state.OwnerPlayer =
		player


	state.OwnerCollisionRefreshTimer =
		0


	if player.Character then

		BindOwnerCharacter(
			state,
			player.Character
		)

	end


	state.CharacterConnection =
		player.CharacterAdded:Connect(
			function(character)

				BindOwnerCharacter(
					state,
					character
				)

			end
		)


	state.CharacterAppearanceConnection =
		player.CharacterAppearanceLoaded:Connect(
			function(character)

				if state.OwnerPlayer ~= player then

					return

				end


				if player.Character ~= character then

					return

				end


				ApplyOwnerCharacterCollision(
					state,
					character
				)

			end
		)


	return true

end


--==================================================
-- RESTORE PLAYER BARRIER
--==================================================

function BarrierService.RestorePlayerBarrier(
	player
)

	local plot =
		PlotService.GetPlayerPlot(
			player
		)

	if not plot then

		return false,
			"NoPlot"

	end


	local data =
		PlayerDataService.GetData(
			player
		)

	if not data then

		return false,
			"DataNotLoaded"

	end


	local state =
		BarrierService.InitializePlot(
			plot
		)


	BarrierService.BindPlayerToPlot(
		player,
		plot
	)


	--==================================================
	-- RESTORE PREMIUM IF ANY TIME REMAINS
	--==================================================

	local premiumRemaining =
		tonumber(
			data.PremiumBarrierRemaining
		)
		or 0


	if premiumRemaining > 0 then

		StartPremiumInternal(
			state,
			premiumRemaining
		)

		return true,
			"PremiumRestored"

	end


	--==================================================
	-- OTHERWISE START NORMAL JOIN PROTECTION
	--==================================================

	data.PremiumBarrierRemaining =
		0


	StartNormalInternal(
		state,
		NORMAL_DURATION
	)


	return true,
		"NormalJoinProtection"

end


--==================================================
-- ACTIVATE NORMAL
--==================================================

function BarrierService.ActivateNormal(
	player
)

	local state =
		BarrierService.GetPlayerState(
			player
		)

	if not state then

		return false,
			"NoPlot"

	end


	if state.Mode
		== STATE_FORCED_UNLOCKED then

		return false,
			"ForcedUnlockActive"

	end


	if state.Mode
		== STATE_NORMAL
		or state.Mode
		== STATE_PREMIUM then

		return false,
			"BarrierAlreadyActive"

	end


	StartNormalInternal(
		state,
		NORMAL_DURATION
	)


	return true,
		"NormalActivated"

end


--==================================================
-- ACTIVATE PREMIUM
--==================================================

function BarrierService.ActivatePremium(
	player
)

	local state =
		BarrierService.GetPlayerState(
			player
		)

	if not state then

		return false,
			"NoPlot"

	end


	local data =
		PlayerDataService.GetData(
			player
		)

	if not data then

		return false,
			"DataNotLoaded"

	end


	if state.Mode
		== STATE_FORCED_UNLOCKED then

		return false,
			"ForcedUnlockActive"

	end


	if state.Mode
		== STATE_PREMIUM then

		return false,
			"BarrierAlreadyActive"

	end


	data.PremiumBarrierRemaining =
		PREMIUM_DURATION


	StartPremiumInternal(
		state,
		PREMIUM_DURATION
	)


	return true,
		"PremiumActivated"

end


--==================================================
-- FORCE UNLOCK NORMAL
--==================================================

function BarrierService.ForceUnlockNormal(
	plot
)

	local state = plotStates[plot]

	if not state then

		return false,
			"PlotNotInitialized"

	end


	-- Premium can never be force-unlocked.

	if state.Mode
		~= STATE_NORMAL then

		return false,
			"NotNormalBarrier"

	end


	state.Mode =
		STATE_FORCED_UNLOCKED

	state.RemainingTime =
		0

	state.ForcedUnlockRemaining =
		FORCED_UNLOCK_DURATION


	HideAllBarriers(
		state
	)

	UpdatePlotAttributes(
		state
	)


	return true,
		"ForcedUnlocked"

end


--==================================================
-- STATE CHECKS
--==================================================

function BarrierService.IsNormalLocked(
	plot
)

	local state = plotStates[plot]

	return state ~= nil
		and state.Mode
		== STATE_NORMAL

end


function BarrierService.IsPremiumLocked(
	plot
)

	local state = plotStates[plot]

	return state ~= nil
		and state.Mode
		== STATE_PREMIUM

end


function BarrierService.IsLocked(
	plot
)

	local state = plotStates[plot]

	if not state then

		return false

	end

	return state.Mode
		== STATE_NORMAL
		or state.Mode
		== STATE_PREMIUM

end


function BarrierService.IsForcedUnlockActive(
	plot
)

	local state = plotStates[plot]

	return state ~= nil
		and state.Mode
		== STATE_FORCED_UNLOCKED

end


function BarrierService.GetForcedUnlockRemaining(
	plot
)

	local state = plotStates[plot]

	if not state then

		return 0

	end

	return math.max(
		0,
		state.ForcedUnlockRemaining
	)

end


--==================================================
-- UPDATE NORMAL
--==================================================

local function UpdateNormal(
	state,
	deltaTime
)

	state.RemainingTime =
		math.max(
			0,
			state.RemainingTime
			- deltaTime
		)


	SetBillboards(
		state.NormalBillboards,
		true,
		state.RemainingTime,
		STATE_NORMAL
	)


	if state.RemainingTime
		<= 0 then

		SetUnlocked(
			state
		)

		return

	end


	UpdatePlotAttributes(
		state
	)

end


--==================================================
-- UPDATE PREMIUM
--==================================================

local function UpdatePremium(
	state,
	deltaTime
)

	state.RemainingTime =
		math.max(
			0,
			state.RemainingTime
			- deltaTime
		)


	local owner =
		state.OwnerPlayer


	if owner then

		local data =
			PlayerDataService.GetData(
				owner
			)

		if data then

			data.PremiumBarrierRemaining =
				state.RemainingTime

		end

	end


	SetBillboards(
		state.PremiumBillboards,
		true,
		state.RemainingTime,
		STATE_PREMIUM
	)


	if state.RemainingTime
		<= 0 then

		if owner then

			local data =
				PlayerDataService.GetData(
					owner
				)

			if data then

				data.PremiumBarrierRemaining =
					0

			end

		end


		SetUnlocked(
			state
		)

		return

	end


	UpdatePlotAttributes(
		state
	)

end


--==================================================
-- UPDATE FORCED UNLOCK
--==================================================

local function UpdateForcedUnlock(
	state,
	deltaTime
)

	state.ForcedUnlockRemaining =
		math.max(
			0,
			state.ForcedUnlockRemaining
			- deltaTime
		)


	if state.ForcedUnlockRemaining
		<= 0 then

		-- Base stays unlocked.
		--
		-- Old Normal barrier does NOT come back.

		SetUnlocked(
			state
		)

		return

	end


	UpdatePlotAttributes(
		state
	)

end


--==================================================
-- UPDATE ALL STATES
--==================================================

local function UpdateState(
	state,
	deltaTime
)

	-- Keep the owner's collision group correct even if
	-- another avatar/character system changes it later.
	if state.OwnerPlayer then

		state.OwnerCollisionRefreshTimer +=
			deltaTime


		if state.OwnerCollisionRefreshTimer >=
			OWNER_COLLISION_REFRESH_INTERVAL then

			state.OwnerCollisionRefreshTimer =
				0


			local character =
				state.OwnerPlayer.Character


			if character
				and character.Parent then

				ApplyOwnerCharacterCollision(
					state,
					character
				)

			end

		end

	end


	if state.Mode
		== STATE_NORMAL then

		UpdateNormal(
			state,
			deltaTime
		)

		return

	end


	if state.Mode
		== STATE_PREMIUM then

		UpdatePremium(
			state,
			deltaTime
		)

		return

	end


	if state.Mode
		== STATE_FORCED_UNLOCKED then

		UpdateForcedUnlock(
			state,
			deltaTime
		)

	end

end


--==================================================
-- START SERVICE
--==================================================

function BarrierService.Start()

	if heartbeatConnection then

		return

	end


	heartbeatConnection =
		RunService.Heartbeat:Connect(
			function(deltaTime)

				for _, state in pairs(
					plotStates
					) do

					UpdateState(
						state,
						deltaTime
					)

				end

			end
		)

end


--==================================================
-- CLEANUP PLAYER
--==================================================

function BarrierService.CleanupPlayer(
	player
)

	local targetState =
		nil


	for _, state in pairs(
		plotStates
		) do

		if state.OwnerPlayer
			== player then

			targetState =
				state

			break

		end

	end


	if not targetState then

		return

	end


	--==================================================
	-- SAVE PREMIUM REMAINING TIME
	--==================================================

	if targetState.Mode
		== STATE_PREMIUM then

		local data =
			PlayerDataService.GetData(
				player
			)

		if data then

			data.PremiumBarrierRemaining =
				math.max(
					0,
					targetState.RemainingTime
				)

		end

	end


	--==================================================
	-- RESET PLAYER CHARACTER COLLISION GROUP
	--==================================================

	if player.Character then

		SetCharacterCollisionGroup(
			player.Character,
			"Default"
		)

	end


	--==================================================
	-- DISCONNECT RESPAWN CONNECTION
	--==================================================

	if targetState.CharacterConnection then

		targetState.CharacterConnection
			:Disconnect()

		targetState.CharacterConnection =
			nil

	end


	if targetState.CharacterAppearanceConnection then

		targetState.CharacterAppearanceConnection:Disconnect()

		targetState.CharacterAppearanceConnection =
			nil

	end


	DisconnectCharacterDescendantConnection(
		targetState
	)


	targetState.OwnerCollisionRefreshTimer =
		0

	targetState.OwnerPlayer =
		nil


	--==================================================
	-- RESET PHYSICAL PLOT
	--==================================================

	SetUnlocked(
		targetState
	)

end


--==================================================
-- AUTO START
--==================================================

BarrierService.Start()


return BarrierService
