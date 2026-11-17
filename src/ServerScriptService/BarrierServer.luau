--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")

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

local PlotService =
	require(
		script.Parent
		:WaitForChild("PlotService")
	)

local BarrierService =
	require(
		script.Parent
		:WaitForChild("BarrierService")
	)

local BarrierPurchaseService =
	require(
		script.Parent
		:WaitForChild("BarrierPurchaseService")
	)

local PlayerFeedbackService =
	require(
		script.Parent
		:WaitForChild("PlayerFeedbackService")
	)


--==================================================
-- WORLD
--==================================================

local Plots =
	workspace:WaitForChild(
		"Plots"
	)


--==================================================
-- REMOTES ROOT
--==================================================

local Remotes =
	ReplicatedStorage:FindFirstChild(
		"Remotes"
	)

if not Remotes then

	Remotes =
		Instance.new("Folder")

	Remotes.Name =
		"Remotes"

	Remotes.Parent =
		ReplicatedStorage

end


--==================================================
-- BARRIER REMOTE FOLDER
--==================================================

local BarrierRemotes =
	Remotes:FindFirstChild(
		"Barrier"
	)

if not BarrierRemotes then

	BarrierRemotes =
		Instance.new("Folder")

	BarrierRemotes.Name =
		"Barrier"

	BarrierRemotes.Parent =
		Remotes

end


--==================================================
-- GET / CREATE REMOTE EVENT
--==================================================

local function GetOrCreateRemoteEvent(
	name
)

	local existing =
		BarrierRemotes:FindFirstChild(
			name
		)

	if existing then

		if existing:IsA(
			"RemoteEvent"
			) then

			return existing

		end

		warn(
			"[BarrierServer]",
			name,
			"exists but is not a RemoteEvent"
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
		BarrierRemotes


	return remote

end


--==================================================
-- REMOTES
--==================================================

local ShowBarrierIsActive =
	GetOrCreateRemoteEvent(
		"ShowBarrierIsActive"
	)

local PromptPremiumBarrierPurchase =
	GetOrCreateRemoteEvent(
		"PromptPremiumBarrierPurchase"
	)

local PromptUnlockBasePurchase =
	GetOrCreateRemoteEvent(
		"PromptUnlockBasePurchase"
	)

local CancelPremiumBarrierPurchase =
	GetOrCreateRemoteEvent(
		"CancelPremiumBarrierPurchase"
	)

local CancelUnlockBasePurchase =
	GetOrCreateRemoteEvent(
		"CancelUnlockBasePurchase"
	)

local ShowPlayerBarrierUnlocked =
	GetOrCreateRemoteEvent(
		"ShowPlayerBarrierUnlocked"
	)


--==================================================
-- SETTINGS
--==================================================

local BUTTON_TOUCH_DEBOUNCE =
	0.75


--==================================================
-- STATE
--==================================================

local buttonTouchTimes =
	{}

local restoredPlayers =
	{}


--==================================================
-- DEBUG
--==================================================

print(
	"[BarrierServer] Started"
)


--==================================================
-- GET PLAYER FROM HIT
--==================================================

local function GetPlayerFromHit(
	hit
)

	if not hit then

		return nil

	end


	local character =
		hit:FindFirstAncestorOfClass(
			"Model"
		)

	if not character then

		return nil

	end


	return Players:GetPlayerFromCharacter(
		character
	)

end


--==================================================
-- TOUCH DEBOUNCE
--==================================================

local function CanProcessButtonTouch(
	buttonPart,
	player
)

	local now = os.clock()

	local buttonState = buttonTouchTimes[buttonPart]

	if not buttonState then

		buttonState =
			{}

		buttonTouchTimes[buttonPart] = buttonState

	end


	local previous = buttonState[player]
		or 0


	if now - previous
		< BUTTON_TOUCH_DEBOUNCE then

		return false

	end


	buttonState[player] = now


	return true

end


--==================================================
-- IS PLOT OWNER
--==================================================

local function IsPlotOwner(
	player,
	plot
)

	if not player
		or not plot then

		return false

	end


	--==================================================
	-- OWNER ATTRIBUTE
	--==================================================

	local ownerUserId =
		plot:GetAttribute(
			"OwnerUserId"
		)


	if ownerUserId
		~= player.UserId then

		return false

	end


	--==================================================
	-- PLOT SERVICE
	--==================================================

	local playerPlot =
		PlotService.GetPlayerPlot(
			player
		)


	if playerPlot
		~= plot then

		return false

	end


	return true

end


--==================================================
-- SHOW BARRIER ALREADY ACTIVE
--==================================================

local function ShowAlreadyActive(
	player
)

	if ShowBarrierIsActive then

		ShowBarrierIsActive:FireClient(
			player
		)

	end


	PlayerFeedbackService.Send(
		player,
		"BarrierDeclined"
	)

end


--==================================================
-- NORMAL BUTTON TOUCHED
--==================================================

local function OnNormalButtonTouched(
	plot,
	buttonPart,
	hit
)

	local player =
		GetPlayerFromHit(
			hit
		)


	if not player then

		return

	end


	print(
		"[BarrierServer]",
		player.Name,
		"touched Normal button on",
		plot.Name
	)


	--==================================================
	-- OWNER ONLY
	--==================================================

	if not IsPlotOwner(
		player,
		plot
		) then

		return

	end


	--==================================================
	-- DEBOUNCE
	--==================================================

	if not CanProcessButtonTouch(
		buttonPart,
		player
		) then

		return

	end


	--==================================================
	-- GET CURRENT BARRIER STATE
	--==================================================

	local state =
		BarrierService.GetPlotState(
			plot
		)


	if not state then

		warn(
			"[BarrierServer] No barrier state for",
			plot.Name
		)

		return

	end


	--==================================================
	-- FORCED UNLOCK ACTIVE
	--==================================================

	-- During the 20-second forced unlock:
	--
	-- Normal button does nothing.
	--
	-- No barrier.
	-- No UI.
	-- No sound.

	if state.Mode
		== BarrierService.States.ForcedUnlocked then

		return

	end


	--==================================================
	-- BARRIER ALREADY ACTIVE
	--==================================================

	-- If Normal or Premium is already active,
	-- do NOT start another barrier.
	--
	-- Instead:
	--
	-- show BarrierIsActiveUI
	-- play BarrierDeclined sound

	if state.Mode
		== BarrierService.States.Normal
		or state.Mode
		== BarrierService.States.Premium then

		ShowAlreadyActive(
			player
		)

		return

	end


	--==================================================
	-- ACTIVATE NORMAL BARRIER
	--==================================================

	local success,
		reason =
		BarrierService.ActivateNormal(
			player
		)


	print(
		"[BarrierServer] ActivateNormal:",
		success,
		reason
	)


	--==================================================
	-- SUCCESS
	--==================================================

	if success then

		-- Play the successful barrier activation sound.

		PlayerFeedbackService.Send(
			player,
			"BarrierSuccessfullyActivated"
		)


		return

	end


	--==================================================
	-- FAILED BECAUSE FORCED UNLOCK STARTED
	--==================================================

	-- This can happen if the barrier state changed
	-- between our earlier state check and this call.

	if reason
		== "ForcedUnlockActive" then

		return

	end


	--==================================================
	-- FAILED BECAUSE BARRIER BECAME ACTIVE
	--==================================================

	if reason
		== "BarrierAlreadyActive" then

		ShowAlreadyActive(
			player
		)

		return

	end


	--==================================================
	-- OTHER FAILURE
	--==================================================

	warn(
		"[BarrierServer] Could not activate Normal Barrier:",
		player.Name,
		reason
	)

end


--==================================================
-- PREMIUM BUTTON TOUCHED
--==================================================

local function OnPremiumButtonTouched(
	plot,
	buttonPart,
	hit
)

	local player =
		GetPlayerFromHit(
			hit
		)


	if not player then

		return

	end


	print(
		"[BarrierServer]",
		player.Name,
		"touched Premium button on",
		plot.Name
	)


	--==================================================
	-- OWNER ONLY
	--==================================================

	if not IsPlotOwner(
		player,
		plot
		) then

		return

	end


	--==================================================
	-- DEBOUNCE
	--==================================================

	if not CanProcessButtonTouch(
		buttonPart,
		player
		) then

		return

	end


	--==================================================
	-- STATE
	--==================================================

	local state =
		BarrierService.GetPlotState(
			plot
		)


	if not state then

		warn(
			"[BarrierServer] No barrier state for",
			plot.Name
		)

		return

	end


	--==================================================
	-- FORCED UNLOCK
	--==================================================

	-- During the 20-second forced unlock:
	--
	-- no Premium purchase prompt
	-- no UI
	-- no sound

	if state.Mode
		== BarrierService.States.ForcedUnlocked then

		return

	end


	--==================================================
	-- PREMIUM ALREADY ACTIVE
	--==================================================

	if state.Mode
		== BarrierService.States.Premium then

		ShowAlreadyActive(
			player
		)

		return

	end


	--==================================================
	-- NORMAL OR UNLOCKED
	--==================================================

	if state.Mode
		== BarrierService.States.Normal
		or state.Mode
		== BarrierService.States.Unlocked then

		local success,
			reason =
			BarrierPurchaseService.BeginPremiumPurchase(
				player
			)


		print(
			"[BarrierServer] BeginPremiumPurchase:",
			success,
			reason
		)


		if not success then

			if reason
				== "PremiumAlreadyActive" then

				ShowAlreadyActive(
					player
				)

			end

			return

		end


		if PromptPremiumBarrierPurchase then

			PromptPremiumBarrierPurchase:FireClient(
				player
			)

		end

	end

end


--==================================================
-- FIND BUTTON
--==================================================

local function FindBarrierButtonPart(
	plot,
	barrierFolderName,
	buttonPartName
)

	local barrierFolder =
		plot:FindFirstChild(
			barrierFolderName
		)


	if not barrierFolder then

		warn(
			"[BarrierServer] Missing",
			barrierFolderName,
			"in",
			plot.Name
		)

		return nil

	end


	local barrierButton =
		barrierFolder:FindFirstChild(
			"BarrierButton"
		)


	if not barrierButton then

		warn(
			"[BarrierServer] Missing BarrierButton in",
			barrierFolder:GetFullName()
		)

		return nil

	end


	local buttonPart =
		barrierButton:FindFirstChild(
			buttonPartName,
			true
		)


	if not buttonPart then

		warn(
			"[BarrierServer] Missing",
			buttonPartName,
			"in",
			barrierButton:GetFullName()
		)

		return nil

	end


	return buttonPart

end


--==================================================
-- SETUP PLOT
--==================================================

local function SetupPlot(
	plot
)

	print(
		"[BarrierServer] Setting up",
		plot.Name
	)


	--==================================================
	-- INITIALIZE SERVICE
	--==================================================

	local state =
		BarrierService.InitializePlot(
			plot
		)


	if not state then

		warn(
			"[BarrierServer] Failed to initialize",
			plot.Name
		)

		return

	end


	--==================================================
	-- NORMAL BUTTON
	--==================================================

	local redButton =
		FindBarrierButtonPart(
			plot,
			"NormalBarrier",
			"RedButtonPart"
		)


	if redButton
		and redButton:IsA(
			"BasePart"
		) then

		redButton.CanTouch =
			true


		print(
			"[BarrierServer] Red button found:",
			redButton:GetFullName()
		)


		redButton.Touched:Connect(
			function(hit)

				OnNormalButtonTouched(
					plot,
					redButton,
					hit
				)

			end
		)

	else

		warn(
			"[BarrierServer] RedButtonPart invalid:",
			plot.Name
		)

	end


	--==================================================
	-- PREMIUM BUTTON
	--==================================================

	local purpleButton =
		FindBarrierButtonPart(
			plot,
			"PremiumBarrier",
			"PurpleButtonPart"
		)


	if purpleButton
		and purpleButton:IsA(
			"BasePart"
		) then

		purpleButton.CanTouch =
			true


		print(
			"[BarrierServer] Purple button found:",
			purpleButton:GetFullName()
		)


		purpleButton.Touched:Connect(
			function(hit)

				OnPremiumButtonTouched(
					plot,
					purpleButton,
					hit
				)

			end
		)

	else

		warn(
			"[BarrierServer] PurpleButtonPart invalid:",
			plot.Name
		)

	end

end


--==================================================
-- RESTORE PLAYER BARRIER
--==================================================

local function RestorePlayerBarrier(
	player
)

	if restoredPlayers[
		player
		] then

		return

	end


	--==================================================
	-- WAIT FOR PLAYER DATA + PLOT
	--==================================================

	local timeoutAt =
		os.clock()
		+ 30


	while player.Parent
		and os.clock()
		< timeoutAt do

		local data =
			PlayerDataService.GetData(
				player
			)


		local plot =
			PlotService.GetPlayerPlot(
				player
			)


		if data
			and plot then

			print(
				"[BarrierServer] Restoring barrier for",
				player.Name,
				"on",
				plot.Name
			)


			local success,
				reason =
				BarrierService.RestorePlayerBarrier(
					player
				)


			if success then

				restoredPlayers[player] = true


				print(
					"[BarrierServer]",
					player.Name,
					"barrier restored:",
					reason
				)


				return

			end


			warn(
				"[BarrierServer] Restore failed:",
				player.Name,
				reason
			)

		end


		task.wait(
			0.25
		)

	end


	warn(
		"[BarrierServer] Timed out waiting for plot/data:",
		player.Name
	)

end


--==================================================
-- PREMIUM PURCHASE CANCELLED
--==================================================

if CancelPremiumBarrierPurchase then

	CancelPremiumBarrierPurchase
		.OnServerEvent
		:Connect(
			function(player)

				BarrierPurchaseService.CancelPremiumPurchase(
					player
				)

			end
		)

end


--==================================================
-- UNLOCK PURCHASE CANCELLED
--==================================================

if CancelUnlockBasePurchase then

	CancelUnlockBasePurchase
		.OnServerEvent
		:Connect(
			function(player)

				BarrierPurchaseService.CancelUnlockPurchase(
					player
				)

			end
		)

end


--==================================================
-- SETUP EXISTING PLOTS
--==================================================

for _, plot in ipairs(
	Plots:GetChildren()
	) do

	SetupPlot(
		plot
	)

end


--==================================================
-- FUTURE PLOTS
--==================================================

Plots.ChildAdded:Connect(
	function(plot)

		task.defer(
			function()

				SetupPlot(
					plot
				)

			end
		)

	end
)


--==================================================
-- PLAYER JOINED
--==================================================

Players.PlayerAdded:Connect(
	function(player)

		task.spawn(
			function()

				RestorePlayerBarrier(
					player
				)

			end
		)

	end
)


--==================================================
-- EXISTING PLAYERS
--==================================================

for _, player in ipairs(
	Players:GetPlayers()
	) do

	task.spawn(
		function()

			RestorePlayerBarrier(
				player
			)

		end
	)

end


--==================================================
-- PLAYER LEAVING
--==================================================

Players.PlayerRemoving:Connect(
	function(player)

		BarrierService.CleanupPlayer(
			player
		)


		BarrierPurchaseService.CleanupPlayer(
			player
		)


		restoredPlayers[player] = nil


		for _,
			buttonState in pairs(
				buttonTouchTimes
			) do

			buttonState[player] = nil

		end

	end
)
