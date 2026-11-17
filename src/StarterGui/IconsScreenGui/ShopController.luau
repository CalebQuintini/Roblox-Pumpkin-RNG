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


local MarketplaceService =
	game:GetService(
		"MarketplaceService"
	)


local TweenService =
	game:GetService(
		"TweenService"
	)


local UserInputService =
	game:GetService(
		"UserInputService"
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
-- ICON GUI
--==================================================

local iconsScreenGui =
	script.Parent


local iconsFrame =
	iconsScreenGui:WaitForChild(
		"Frame"
	)


local shopImageLabel =
	iconsFrame:WaitForChild(
		"ShopImageLabel"
	)


--==================================================
-- SHOP GUI
--==================================================

local shopScreenGui =
	playerGui:WaitForChild(
		"ShopScreenGui"
	)


local shopScreenFrame =
	shopScreenGui:WaitForChild(
		"ShopScreenFrame"
	)


local exitButton =
	shopScreenFrame:WaitForChild(
		"ExitButton"
	)


local scrollingFrame =
	shopScreenFrame:WaitForChild(
		"ScrollingFrame"
	)


--==================================================
-- STARTER PACK
--==================================================

local starterPackFrame =
	scrollingFrame:WaitForChild(
		"StarterPackFrame"
	)


local starterPackPurchaseButton =
	starterPackFrame:WaitForChild(
		"PurchaseImageButton"
	)


--==================================================
-- CASH PACK
--==================================================

local cashPackFrame =
	scrollingFrame:WaitForChild(
		"CashPackFrame"
	)


local bigPackFrame =
	cashPackFrame:WaitForChild(
		"BigPackMoneyFrame"
	)


local mediumPackFrame =
	cashPackFrame:WaitForChild(
		"MediumPackMoneyFrame"
	)


local smallPackFrame =
	cashPackFrame:WaitForChild(
		"SmallPackMoneyFrame"
	)


local bigPackPurchaseButton =
	bigPackFrame:WaitForChild(
		"PurchaseImageButton"
	)


local mediumPackPurchaseButton =
	mediumPackFrame:WaitForChild(
		"PurchaseImageButton"
	)


local smallPackPurchaseButton =
	smallPackFrame:WaitForChild(
		"PurchaseImageButton"
	)


--==================================================
-- PRODUCT IDS
--==================================================

local STARTER_PACK_PRODUCT_ID =
	3718958066


local BIG_PACK_PRODUCT_ID =
	3718958031


local MEDIUM_PACK_PRODUCT_ID =
	3718958012


local SMALL_PACK_PRODUCT_ID =
	3718957990


--==================================================
-- REMOTES
--==================================================

local ShopRemotes =
	ReplicatedStorage
	:WaitForChild(
		"Remotes"
	)
	:WaitForChild(
		"Shop"
	)


local GetShopState =
	ShopRemotes:WaitForChild(
		"GetShopState"
	)


local ShopStateUpdated =
	ShopRemotes:WaitForChild(
		"ShopStateUpdated"
	)


--==================================================
-- ANIMATION SETTINGS
--==================================================

local NORMAL_SCALE =
	1


local HOVER_SCALE =
	1.08


local CLICK_SCALE =
	0.92


local HOVER_TIME =
	0.12


local CLICK_TIME =
	0.07


--==================================================
-- STARTER PACK STATE
--==================================================

local starterPackBought =
	false


--==================================================
-- GET / CREATE UI SCALE
--==================================================

local function GetScale(
	guiObject
)

	local scale =
		guiObject:FindFirstChild(
			"ButtonScale"
		)


	if not scale then

		scale =
			Instance.new(
				"UIScale"
			)


		scale.Name =
			"ButtonScale"


		scale.Scale =
			NORMAL_SCALE


		scale.Parent =
			guiObject

	end


	return scale

end


--==================================================
-- TWEEN SCALE
--==================================================

local function TweenScale(
	guiObject,
	targetScale,
	duration
)

	local scale =
		GetScale(
			guiObject
		)


	TweenService:Create(
		scale,

		TweenInfo.new(
			duration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),

		{
			Scale =
				targetScale,
		}
	):Play()

end


--==================================================
-- BUTTON ANIMATION
--==================================================

local function SetupButtonAnimation(
	guiObject
)

	GetScale(
		guiObject
	)


	guiObject.MouseEnter:Connect(
		function()

			TweenScale(
				guiObject,
				HOVER_SCALE,
				HOVER_TIME
			)

		end
	)


	guiObject.MouseLeave:Connect(
		function()

			TweenScale(
				guiObject,
				NORMAL_SCALE,
				HOVER_TIME
			)

		end
	)


	guiObject.MouseButton1Down:Connect(
		function()

			TweenScale(
				guiObject,
				CLICK_SCALE,
				CLICK_TIME
			)

		end
	)


	guiObject.MouseButton1Up:Connect(
		function()

			TweenScale(
				guiObject,
				HOVER_SCALE,
				CLICK_TIME
			)

		end
	)

end


--==================================================
-- IMAGE LABEL ANIMATION
--==================================================

local function SetupImageLabelAnimation(
	imageLabel
)

	imageLabel.Active =
		true


	GetScale(
		imageLabel
	)


	imageLabel.MouseEnter:Connect(
		function()

			TweenScale(
				imageLabel,
				HOVER_SCALE,
				HOVER_TIME
			)

		end
	)


	imageLabel.MouseLeave:Connect(
		function()

			TweenScale(
				imageLabel,
				NORMAL_SCALE,
				HOVER_TIME
			)

		end
	)


	imageLabel.InputBegan:Connect(
		function(input)

			if input.UserInputType
				~= Enum.UserInputType.MouseButton1
				and input.UserInputType
				~= Enum.UserInputType.Touch then

				return

			end


			TweenScale(
				imageLabel,
				CLICK_SCALE,
				CLICK_TIME
			)

		end
	)


	imageLabel.InputEnded:Connect(
		function(input)

			if input.UserInputType
				~= Enum.UserInputType.MouseButton1
				and input.UserInputType
				~= Enum.UserInputType.Touch then

				return

			end


			TweenScale(
				imageLabel,
				HOVER_SCALE,
				CLICK_TIME
			)

		end
	)

end


--==================================================
-- STARTER PACK BOUGHT OVERLAY
--==================================================

local function GetStarterPackBoughtOverlay()

	local overlay =
		starterPackFrame:FindFirstChild(
			"BoughtOverlay"
		)


	if overlay then

		return overlay

	end


	--==================================================
	-- GREY OVERLAY
	--==================================================

	overlay =
		Instance.new(
			"Frame"
		)


	overlay.Name =
		"BoughtOverlay"


	overlay.Size =
		UDim2.fromScale(
			1,
			1
		)


	overlay.Position =
		UDim2.fromScale(
			0,
			0
		)


	overlay.BackgroundColor3 =
		Color3.fromRGB(
			75,
			75,
			75
		)


	overlay.BackgroundTransparency =
		0.3


	overlay.BorderSizePixel =
		0


	overlay.ZIndex =
		50


	overlay.Parent =
		starterPackFrame


	--==================================================
	-- BOUGHT TEXT
	--==================================================

	local boughtText =
		Instance.new(
			"TextLabel"
		)


	boughtText.Name =
		"BoughtText"


	boughtText.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)


	boughtText.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)


	boughtText.Size =
		UDim2.fromScale(
			0.8,
			0.3
		)


	boughtText.BackgroundTransparency =
		1


	boughtText.Text =
		"BOUGHT"


	boughtText.TextColor3 =
		Color3.fromRGB(
			255,
			255,
			255
		)


	boughtText.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)


	boughtText.TextStrokeTransparency =
		0


	boughtText.TextScaled =
		true


	boughtText.Font =
		Enum.Font.FredokaOne


	boughtText.ZIndex =
		51


	boughtText.Parent =
		overlay


	return overlay

end


--==================================================
-- UPDATE STARTER PACK
--==================================================

local function UpdateStarterPack()

	local overlay =
		GetStarterPackBoughtOverlay()


	overlay.Visible =
		starterPackBought


	starterPackPurchaseButton.Active =
		not starterPackBought


	starterPackPurchaseButton.AutoButtonColor =
		false


	if starterPackBought then

		starterPackPurchaseButton.ImageColor3 =
			Color3.fromRGB(
				110,
				110,
				110
			)

	else

		starterPackPurchaseButton.ImageColor3 =
			Color3.fromRGB(
				255,
				255,
				255
			)

	end

end


--==================================================
-- APPLY SHOP STATE
--==================================================

local function ApplyShopState(
	state
)

	if type(state)
		~= "table" then

		return

	end


	starterPackBought =
		state.StarterPackBought
		== true


	UpdateStarterPack()

end


--==================================================
-- OPEN SHOP
--==================================================

local function OpenShop()

	--==================================================
	-- BLOCK SHOP DURING TUTORIAL
	--==================================================

	-- TutorialServer / TutorialService sets this
	-- Attribute while the player is completing the
	-- Roll -> Buy -> Place tutorial.
	--
	-- The Pumpkin Index remains available; only the
	-- Shop is blocked.

	if player:GetAttribute(
		"TutorialActive"
		) then

		return

	end


	shopScreenFrame.Visible =
		true

end


--==================================================
-- CLOSE SHOP
--==================================================

local function CloseShop()

	shopScreenFrame.Visible =
		false

end


--==================================================
-- ICON ANIMATIONS
--==================================================

SetupImageLabelAnimation(
	shopImageLabel
)


--==================================================
-- SHOP ICON CLICK
--==================================================

shopImageLabel.InputEnded:Connect(
	function(input)

		if input.UserInputType
			~= Enum.UserInputType.MouseButton1
			and input.UserInputType
			~= Enum.UserInputType.Touch then

			return

		end


		OpenShop()

	end
)


--==================================================
-- SHOP BUTTON ANIMATIONS
--==================================================

SetupButtonAnimation(
	exitButton
)


SetupButtonAnimation(
	starterPackPurchaseButton
)


SetupButtonAnimation(
	bigPackPurchaseButton
)


SetupButtonAnimation(
	mediumPackPurchaseButton
)


SetupButtonAnimation(
	smallPackPurchaseButton
)


--==================================================
-- EXIT SHOP
--==================================================

exitButton.Activated:Connect(
	function()

		CloseShop()

	end
)


--==================================================
-- STARTER PACK
--==================================================

starterPackPurchaseButton.Activated:Connect(
	function()

		if starterPackBought then

			return

		end


		MarketplaceService
			:PromptProductPurchase(
				player,
				STARTER_PACK_PRODUCT_ID
			)

	end
)


--==================================================
-- BIG CASH PACK
--==================================================

bigPackPurchaseButton.Activated:Connect(
	function()

		MarketplaceService
			:PromptProductPurchase(
				player,
				BIG_PACK_PRODUCT_ID
			)

	end
)


--==================================================
-- MEDIUM CASH PACK
--==================================================

mediumPackPurchaseButton.Activated:Connect(
	function()

		MarketplaceService
			:PromptProductPurchase(
				player,
				MEDIUM_PACK_PRODUCT_ID
			)

	end
)


--==================================================
-- SMALL CASH PACK
--==================================================

smallPackPurchaseButton.Activated:Connect(
	function()

		MarketplaceService
			:PromptProductPurchase(
				player,
				SMALL_PACK_PRODUCT_ID
			)

	end
)


--==================================================
-- SERVER SHOP UPDATE
--==================================================

ShopStateUpdated.OnClientEvent:Connect(
	function(state)

		ApplyShopState(
			state
		)

	end
)


--==================================================
-- INITIAL STATE
--==================================================

shopScreenGui.Enabled =
	true


shopScreenFrame.Visible =
	false


--==================================================
-- TUTORIAL STATE CHANGED
--==================================================

-- If TutorialActive becomes true while the Shop is
-- already open for any reason, close it immediately.

player:GetAttributeChangedSignal(
	"TutorialActive"
):Connect(
	function()

		if player:GetAttribute(
			"TutorialActive"
			) then

			CloseShop()

		end

	end
)


task.spawn(
	function()

		while true do

			local success,
			state =
				pcall(
					function()

						return GetShopState
						:InvokeServer()

					end
				)


			if success then

				ApplyShopState(
					state
				)


				break

			end


			task.wait(
				0.5
			)

		end

	end
)
