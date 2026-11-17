--==================================================
-- WORLD
--==================================================

local Plots =
	workspace:WaitForChild(
		"Plots"
	)

--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

local MarketplaceService =
	game:GetService("MarketplaceService")


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
-- PRODUCT IDS
--==================================================

-- 10 MIN BASE LOCK
local PREMIUM_BARRIER_PRODUCT_ID =
	3718428383


-- UNLOCK BASE
local UNLOCK_BASE_PRODUCT_ID =
	3718428646


--==================================================
-- UI TEMPLATES
--==================================================

local Assets =
	ReplicatedStorage:WaitForChild(
		"Assets"
	)

local UI =
	Assets:WaitForChild(
		"UI"
	)


local BarrierIsActiveTemplate =
	UI:WaitForChild(
		"BarrierIsActiveUI"
	)

local PlayerBarrierUnlockedTemplate =
	UI:WaitForChild(
		"PlayerBarrierUnlockedUI"
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage:WaitForChild(
		"Remotes"
	)

local BarrierRemotes =
	Remotes:WaitForChild(
		"Barrier"
	)


--==================================================
-- UI REMOTES
--==================================================

local ShowBarrierIsActive =
	BarrierRemotes:WaitForChild(
		"ShowBarrierIsActive"
	)

local ShowPlayerBarrierUnlocked =
	BarrierRemotes:WaitForChild(
		"ShowPlayerBarrierUnlocked"
	)


--==================================================
-- PURCHASE REMOTES
--==================================================

local PromptPremiumBarrierPurchase =
	BarrierRemotes:WaitForChild(
		"PromptPremiumBarrierPurchase"
	)

local PromptUnlockBasePurchase =
	BarrierRemotes:WaitForChild(
		"PromptUnlockBasePurchase"
	)

local CancelPremiumBarrierPurchase =
	BarrierRemotes:WaitForChild(
		"CancelPremiumBarrierPurchase"
	)

local CancelUnlockBasePurchase =
	BarrierRemotes:WaitForChild(
		"CancelUnlockBasePurchase"
	)


--==================================================
-- SETTINGS
--==================================================

local BARRIER_ACTIVE_UI_DURATION =
	1

local DEFAULT_UNLOCKED_UI_DURATION =
	20


--==================================================
-- STATE
--==================================================

local activeBarrierUi =
	nil

local activeBarrierUiToken =
	0


local activeUnlockedUi =
	nil

local activeUnlockedUiToken =
	0


--==================================================
-- DEBUG
--==================================================

print(
	"[BarrierController] Started"
)


--==================================================
-- ENABLE GUI
--==================================================

local function EnableGui(
	gui
)

	if not gui then

		return

	end


	if gui:IsA(
		"ScreenGui"
		) then

		gui.Enabled =
			true

		return

	end


	if gui:IsA(
		"GuiObject"
		) then

		gui.Visible =
			true

	end

end


--==================================================
-- FIND FIRST TEXT LABEL
--==================================================

local function FindTextLabel(
	gui
)

	if not gui then

		return nil

	end


	if gui:IsA(
		"TextLabel"
		) then

		return gui

	end


	for _, descendant in ipairs(
		gui:GetDescendants()
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
-- REMOVE BARRIER ACTIVE UI
--==================================================

local function RemoveBarrierActiveUI()

	if activeBarrierUi
		and activeBarrierUi.Parent then

		activeBarrierUi:Destroy()

	end


	activeBarrierUi =
		nil

end


--==================================================
-- REMOVE BASE UNLOCKED UI
--==================================================

local function RemoveUnlockedUI()

	if activeUnlockedUi
		and activeUnlockedUi.Parent then

		activeUnlockedUi:Destroy()

	end


	activeUnlockedUi =
		nil

end


--==================================================
-- SHOW BARRIER IS ACTIVE UI
--==================================================

local function ShowBarrierActiveUI()

	-- If triggered again while already visible,
	-- restart the full 10-second duration.

	RemoveBarrierActiveUI()


	activeBarrierUiToken += 1


	local token =
		activeBarrierUiToken


	--==================================================
	-- CLONE TEMPLATE
	--==================================================

	local clone =
		BarrierIsActiveTemplate:Clone()


	--==================================================
	-- TEMPLATE IS A SCREEN GUI
	--==================================================

	if clone:IsA("ScreenGui") then

		clone.Name =
			"BarrierIsActiveUI"


		clone.Enabled =
			true


		clone.Parent =
			playerGui


		activeBarrierUi =
			clone


		--==================================================
		-- TEMPLATE IS A FRAME / GUI OBJECT
		--==================================================

	elseif clone:IsA("GuiObject") then

		local screenGui =
			Instance.new(
				"ScreenGui"
			)


		screenGui.Name =
			"BarrierIsActiveUI"


		screenGui.ResetOnSpawn =
			false


		screenGui.IgnoreGuiInset =
			true


		screenGui.Parent =
			playerGui


		clone.Visible =
			true


		clone.Parent =
			screenGui


		activeBarrierUi =
			screenGui


	else

		warn(
			"[BarrierController] BarrierIsActiveUI must be a ScreenGui or GuiObject."
		)


		clone:Destroy()


		return

	end


	print(
		"[BarrierController] Showing BarrierIsActiveUI"
	)


	--==================================================
	-- REMOVE AFTER 10 SECONDS
	--==================================================

	task.delay(
		BARRIER_ACTIVE_UI_DURATION,

		function()

			if token
				~= activeBarrierUiToken then

				return

			end


			RemoveBarrierActiveUI()

		end
	)

end


--==================================================
-- UPDATE UNLOCKED UI TEXT
--==================================================

local function UpdateUnlockedText(
	textLabel,
	remaining
)

	if not textLabel
		or not textLabel.Parent then

		return

	end


	textLabel.Text =
		"Your Base Has Been Unlocked. "
		.. "Base Cannot Be Locked for "
		.. remaining
		.. " seconds."

end


--==================================================
-- SHOW PLAYER BASE UNLOCKED UI
--==================================================

local function ShowPlayerBaseUnlockedUI(
	duration
)

	duration =
		tonumber(
			duration
		)
		or DEFAULT_UNLOCKED_UI_DURATION


	duration =
		math.max(
			0,
			duration
		)


	--==================================================
	-- REMOVE OLD VERSION
	--==================================================

	RemoveUnlockedUI()


	activeUnlockedUiToken +=
		1


	local token =
		activeUnlockedUiToken


	--==================================================
	-- CLONE TEMPLATE
	--==================================================

	local clone =
		PlayerBarrierUnlockedTemplate:Clone()


	--==================================================
	-- TEMPLATE IS A SCREEN GUI
	--==================================================

	if clone:IsA("ScreenGui") then

		clone.Name =
			"PlayerBarrierUnlockedUI"


		clone.Enabled =
			true


		clone.Parent =
			playerGui


		activeUnlockedUi =
			clone


		--==================================================
		-- TEMPLATE IS A FRAME / GUI OBJECT
		--==================================================

	elseif clone:IsA("GuiObject") then

		local screenGui =
			Instance.new(
				"ScreenGui"
			)


		screenGui.Name =
			"PlayerBarrierUnlockedUI"


		screenGui.ResetOnSpawn =
			false


		screenGui.IgnoreGuiInset =
			true


		screenGui.Parent =
			playerGui


		clone.Visible =
			true


		clone.Parent =
			screenGui


		activeUnlockedUi =
			screenGui


	else

		warn(
			"[BarrierController] PlayerBarrierUnlockedUI must be a ScreenGui or GuiObject."
		)


		clone:Destroy()


		return

	end


	print(
		"[BarrierController] Showing PlayerBarrierUnlockedUI"
	)


	--==================================================
	-- FIND TEXT LABEL
	--==================================================

	local textLabel =
		FindTextLabel(
			activeUnlockedUi
		)


	if not textLabel then

		warn(
			"[BarrierController] No TextLabel found inside PlayerBarrierUnlockedUI"
		)

	end


	--==================================================
	-- LIVE COUNTDOWN
	--==================================================

	task.spawn(
		function()

			local endTime =
				os.clock()
				+ duration


			while token
				== activeUnlockedUiToken do

				local remaining =
					math.max(
						0,
						math.ceil(
							endTime
							- os.clock()
						)
					)


				UpdateUnlockedText(
					textLabel,
					remaining
				)


				if remaining
					<= 0 then

					break

				end


				task.wait(
					0.1
				)

			end


			if token
				== activeUnlockedUiToken then

				RemoveUnlockedUI()

			end

		end
	)

end

--==================================================
-- UPDATE UNLOCK PROMPTS FOR LOCAL PLAYER
--==================================================

local function UpdatePlotUnlockPrompts(
	plot
)

	if not plot then
		return
	end


	--==================================================
	-- IS THIS OUR OWN PLOT?
	--==================================================

	local isOwner =
		plot:GetAttribute(
			"OwnerUserId"
		) == player.UserId


	--==================================================
	-- IS NORMAL BARRIER ACTIVE?
	--==================================================

	local barrierState =
		plot:GetAttribute(
			"BarrierState"
		)


	local normalBarrierActive =
		barrierState == "Normal"


	--==================================================
	-- FIND NORMAL BARRIER
	--==================================================

	local normalBarrier =
		plot:FindFirstChild(
			"NormalBarrier"
		)


	if not normalBarrier then
		return
	end


	local barrierModel =
		normalBarrier:FindFirstChild(
			"BarrierModel"
		)


	if not barrierModel then
		return
	end


	--==================================================
	-- UPDATE BOTH UNLOCK BASE PROMPTS
	--==================================================

	for _, descendant in ipairs(
		barrierModel:GetDescendants()
		) do

		if descendant:IsA("ProximityPrompt")
			and descendant.Name == "UnlockBasePrompt" then

			-- The prompt should only appear when:
			--
			-- 1. Normal Barrier is active
			-- 2. This plot does NOT belong to us

			descendant.Enabled =
				normalBarrierActive
				and not isOwner

		end

	end

end


--==================================================
-- SETUP ONE PLOT'S LOCAL PROMPTS
--==================================================

local function SetupPlotUnlockPrompts(
	plot
)

	-- Update immediately.

	UpdatePlotUnlockPrompts(
		plot
	)


	--==================================================
	-- BARRIER STATE CHANGED
	--==================================================

	plot:GetAttributeChangedSignal(
		"BarrierState"
	):Connect(
		function()

			UpdatePlotUnlockPrompts(
				plot
			)

		end
	)


	--==================================================
	-- OWNER CHANGED
	--==================================================

	plot:GetAttributeChangedSignal(
		"OwnerUserId"
	):Connect(
		function()

			UpdatePlotUnlockPrompts(
				plot
			)

		end
	)

end


--==================================================
-- EXISTING PLOTS
--==================================================

for _, plot in ipairs(
	Plots:GetChildren()
	) do

	SetupPlotUnlockPrompts(
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

				SetupPlotUnlockPrompts(
					plot
				)

			end
		)

	end
)


--==================================================
-- BARRIER ACTIVE REMOTE
--==================================================

ShowBarrierIsActive.OnClientEvent:Connect(
	function()

		ShowBarrierActiveUI()

	end
)


--==================================================
-- PLAYER BASE UNLOCKED REMOTE
--==================================================

ShowPlayerBarrierUnlocked.OnClientEvent:Connect(
	function(duration)

		ShowPlayerBaseUnlockedUI(
			duration
		)

	end
)


--==================================================
-- PREMIUM PURCHASE PROMPT
--==================================================

PromptPremiumBarrierPurchase.OnClientEvent:Connect(
	function()

		print(
			"[BarrierController] Opening Premium purchase prompt"
		)


		MarketplaceService:PromptProductPurchase(
			player,
			PREMIUM_BARRIER_PRODUCT_ID
		)

	end
)


--==================================================
-- UNLOCK BASE PURCHASE PROMPT
--==================================================

PromptUnlockBasePurchase.OnClientEvent:Connect(
	function()

		print(
			"[BarrierController] Opening Unlock Base purchase prompt"
		)


		MarketplaceService:PromptProductPurchase(
			player,
			UNLOCK_BASE_PRODUCT_ID
		)

	end
)


--==================================================
-- PURCHASE PROMPT FINISHED
--==================================================

MarketplaceService
	.PromptProductPurchaseFinished
	:Connect(
		function(
			userId,
			productId,
			wasPurchased
		)

			--==================================================
			-- ONLY LOCAL PLAYER
			--==================================================

			if userId
				~= player.UserId then

				return

			end


			--==================================================
			-- PREMIUM BARRIER
			--==================================================

			if productId
				== PREMIUM_BARRIER_PRODUCT_ID then

				if not wasPurchased then

					print(
						"[BarrierController] Premium purchase cancelled"
					)


					CancelPremiumBarrierPurchase
					:FireServer()

				end


				-- Do not grant Premium here.
				--
				-- Server-side ProcessReceipt handles it.

				return

			end


			--==================================================
			-- UNLOCK BASE
			--==================================================

			if productId
				== UNLOCK_BASE_PRODUCT_ID then

				if not wasPurchased then

					print(
						"[BarrierController] Unlock Base purchase cancelled"
					)


					CancelUnlockBasePurchase
					:FireServer()

				end


				-- Do not unlock the base here.
				--
				-- Server-side ProcessReceipt handles it.

				return

			end

		end
	)
