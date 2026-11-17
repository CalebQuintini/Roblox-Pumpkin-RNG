--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


local SoundService =
	game:GetService("SoundService")


local Debris =
	game:GetService("Debris")


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
-- ASSETS
--==================================================

local Assets =
	ReplicatedStorage:WaitForChild(
		"Assets"
	)


local Sounds =
	Assets:WaitForChild(
		"Sounds"
	)


local UI =
	Assets:WaitForChild(
		"UI"
	)


--==================================================
-- SOUND TEMPLATES
--==================================================

local PurchaseSuccessSound =
	Sounds:WaitForChild(
		"PurchaseSuccess"
	)


local PurchaseDeclinedSound =
	Sounds:WaitForChild(
		"PurchaseDeclined"
	)


local PumpkinMoneyCollectSound =
	Sounds:WaitForChild(
		"PumpkinMoneyCollect"
	)


local PumpkinPlacePickupSound =
	Sounds:WaitForChild(
		"PumpkinPlacePickup"
	)


local PlayerBaseUnlockedSound =
	Sounds:WaitForChild(
		"PlayerBaseUnlocked"
	)

local BarrierSuccessfullyActivatedSound =
	Sounds:WaitForChild(
		"BarrieSuccessfullyActivated"
	)


--==================================================
-- UI TEMPLATE
--==================================================

local PurchaseDeclinedTemplate =
	UI:WaitForChild(
		"PurchaseDeclinedTemplate"
	)


--==================================================
-- REMOTES
--==================================================

local ShowFeedback =
	ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild("PlayerFeedback")
	:WaitForChild("ShowFeedback")


--==================================================
-- SETTINGS
--==================================================

local DECLINED_DISPLAY_TIME =
	1


--==================================================
-- CREATE FEEDBACK GUI
--==================================================

local feedbackGui =
	Instance.new(
		"ScreenGui"
	)


feedbackGui.Name =
	"PlayerFeedbackGui"


feedbackGui.ResetOnSpawn =
	false


feedbackGui.IgnoreGuiInset =
	true


feedbackGui.Parent =
	playerGui


--==================================================
-- NOTIFICATION CONTAINER
--==================================================

local notificationContainer =
	Instance.new(
		"Frame"
	)


notificationContainer.Name =
	"NotificationContainer"


notificationContainer.AnchorPoint =
	Vector2.new(
		0.5,
		1
	)


notificationContainer.Position =
	UDim2.fromScale(
		0.5,
		0.82
	)


notificationContainer.Size =
	UDim2.fromScale(
		0.35,
		0.45
	)


notificationContainer.BackgroundTransparency =
	1


notificationContainer.Parent =
	feedbackGui


--==================================================
-- UI LIST LAYOUT
--==================================================

local listLayout =
	Instance.new(
		"UIListLayout"
	)


listLayout.Name =
	"NotificationLayout"


listLayout.FillDirection =
	Enum.FillDirection.Vertical


listLayout.HorizontalAlignment =
	Enum.HorizontalAlignment.Center


listLayout.VerticalAlignment =
	Enum.VerticalAlignment.Bottom


listLayout.SortOrder =
	Enum.SortOrder.LayoutOrder


listLayout.Padding =
	UDim.new(
		0.02,
		0
	)


listLayout.Parent =
	notificationContainer


--==================================================
-- STATE
--==================================================

local nextNotificationOrder =
	0


--==================================================
-- PLAY LOCAL SOUND
--==================================================

local function PlaySound(
	soundTemplate
)

	if not soundTemplate then

		return

	end


	local sound =
		soundTemplate:Clone()


	sound.Parent =
		SoundService


	sound:Play()


	Debris:AddItem(
		sound,
		30
	)

end


--==================================================
-- SHOW PURCHASE DECLINED UI
--==================================================

local function ShowPurchaseDeclined()

	nextNotificationOrder +=
		1


	local notification =
		PurchaseDeclinedTemplate:Clone()


	notification.Name =
		"PurchaseDeclined_"
		.. nextNotificationOrder


	notification.LayoutOrder =
		nextNotificationOrder


	notification.Visible =
		true


	notification.Parent =
		notificationContainer


	task.delay(
		DECLINED_DISPLAY_TIME,

		function()

			if notification
				and notification.Parent then

				notification:Destroy()

			end

		end
	)

end


--==================================================
-- HANDLE FEEDBACK
--==================================================

local function HandleFeedback(
	feedbackType
)

	--==================================================
	-- PURCHASE SUCCESS
	--==================================================

	if feedbackType
		== "PurchaseSuccess" then

		PlaySound(
			PurchaseSuccessSound
		)


		return

	end


	--==================================================
	-- PURCHASE DECLINED
	--==================================================

	if feedbackType
		== "PurchaseDeclined" then

		PlaySound(
			PurchaseDeclinedSound
		)


		ShowPurchaseDeclined()


		return

	end
	
	--==================================================
	-- BARRIER SUCCESSFULLY ACTIVATED
	--==================================================

	if feedbackType
		== "BarrierSuccessfullyActivated" then

		PlaySound(
			BarrierSuccessfullyActivatedSound
		)

		return

	end


	--==================================================
	-- BARRIER DECLINED
	--==================================================

	-- Same sound as PurchaseDeclined,
	--
	-- BUT:
	--
	-- do NOT show the Can't Afford UI.
	--
	-- BarrierIsActiveUI will be shown separately.

	if feedbackType
		== "BarrierDeclined" then

		PlaySound(
			PurchaseDeclinedSound
		)


		return

	end


	--==================================================
	-- PUMPKIN MONEY COLLECTION
	--==================================================

	if feedbackType
		== "PumpkinMoneyCollect" then

		PlaySound(
			PumpkinMoneyCollectSound
		)


		return

	end


	--==================================================
	-- PUMPKIN PLACE / PICKUP
	--==================================================

	if feedbackType
		== "PumpkinPlacePickup" then

		PlaySound(
			PumpkinPlacePickupSound
		)


		return

	end


	--==================================================
	-- PLAYER BASE UNLOCKED
	--==================================================

	if feedbackType
		== "PlayerBaseUnlocked" then

		PlaySound(
			PlayerBaseUnlockedSound
		)


		return

	end


	--==================================================
	-- UNKNOWN FEEDBACK
	--==================================================

	warn(
		"[PlayerFeedbackController] Unknown feedback type:",
		feedbackType
	)

end


--==================================================
-- REMOTE EVENT
--==================================================

ShowFeedback.OnClientEvent:Connect(
	HandleFeedback
)
