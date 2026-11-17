--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


local UserInputService =
	game:GetService("UserInputService")

local TweenService =
	game:GetService("TweenService")


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
-- CURRENT GUI
--==================================================

local gui =
	script.Parent


local pumpkinIndexFrame =
	gui:WaitForChild(
		"PumpkinIndexFrame"
	)


local scrollingFrame =
	pumpkinIndexFrame:WaitForChild(
		"ScrollingFrame"
	)


local exitButton =
	pumpkinIndexFrame:WaitForChild(
		"ExitButton"
	)


--==================================================
-- ICONS GUI
--==================================================

local iconsGui =
	playerGui:WaitForChild(
		"IconsScreenGui"
	)


local iconsFrame =
	iconsGui:WaitForChild(
		"Frame"
	)


local indexImageLabel =
	iconsFrame:WaitForChild(
		"IndexImageLabel"
	)


--==================================================
-- MODULES
--==================================================

local PumpkinConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("PumpkinConfig")
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild("Remotes")


local GetPumpkinIndex =
	Remotes:WaitForChild(
		"GetPumpkinIndex"
	)


local PumpkinIndexUpdated =
	Remotes:WaitForChild(
		"PumpkinIndexUpdated"
	)


--==================================================
-- STATE
--==================================================

local unlockedPumpkins =
	{}


local indexFrames =
	{}




--==================================================
-- COMPACT NUMBER
--==================================================

-- Examples:
--
-- 5        -> 5
-- 1000     -> 1K
-- 21600    -> 21.6K
-- 1000000  -> 1M
-- 23000000 -> 23M

local function CompactNumber(
	number
)

	if type(number)
		~= "number" then

		return "0"

	end


	local absolute =
		math.abs(
			number
		)


	local suffix =
		""


	local divisor =
		1


	if absolute >= 1e12 then

		suffix =
			"T"


		divisor =
			1e12


	elseif absolute >= 1e9 then

		suffix =
			"B"


		divisor =
			1e9


	elseif absolute >= 1e6 then

		suffix =
			"M"


		divisor =
			1e6


	elseif absolute >= 1e3 then

		suffix =
			"K"


		divisor =
			1e3

	end


	local value =
		number / divisor


	--==================================================
	-- NO SUFFIX
	--==================================================

	if suffix == "" then

		if value == math.floor(
			value
			) then

			return tostring(
				math.floor(
					value
				)
			)

		end


		return string.format(
			"%.1f",
			value
		)

	end


	--==================================================
	-- COMPACT VALUE
	--==================================================

	local formatted


	if value >= 100 then

		formatted =
			string.format(
				"%.0f",
				value
			)


	elseif value >= 10 then

		formatted =
			string.format(
				"%.1f",
				value
			)


	else

		formatted =
			string.format(
				"%.2f",
				value
			)

	end


	-- Remove unnecessary zeroes:
	--
	-- 21.0K -> 21K
	-- 1.00M -> 1M
	-- 1.50M -> 1.5M

	formatted =
		formatted:gsub(
			"(%..-)0+$",
			"%1"
		)


	formatted =
		formatted:gsub(
			"%.$",
			""
		)


	return formatted
		.. suffix

end


--==================================================
-- GET INDEX FRAMES
--==================================================

local function GetIndexFrames()

	local frames =
		{}


	for index = 1, #PumpkinConfig.Order do

		local frame =
			scrollingFrame:FindFirstChild(
				"Index" .. index
			)


		if frame
			and frame:IsA("Frame") then

			-- Force the visual order too.

			frame.LayoutOrder =
				index


			frames[index] =
				frame

		else

			warn(
				"[PumpkinIndexController] Missing frame:",
				"Index" .. index
			)

		end

	end


	return frames

end


--==================================================
-- GET FRAME REFERENCES
--==================================================

local function GetFrameReferences(
	frame
)

	local pumpkinImageLabel =
		frame:FindFirstChild(
			"PumpkinImageLabel"
		)


	local oneInTextLabel =
		frame:FindFirstChild(
			"1inTextLabel"
		)


	local dollarTextLabel =
		frame:FindFirstChild(
			"DollarTextLabel"
		)


	local pumpkinHeadingTextLabel =
		frame:FindFirstChild(
			"PumpkinHeadingTextLabel"
		)


	if not pumpkinImageLabel
		or not pumpkinImageLabel:IsA(
			"ImageLabel"
		) then

		return nil

	end


	if not oneInTextLabel
		or not oneInTextLabel:IsA(
			"TextLabel"
		) then

		return nil

	end


	if not dollarTextLabel
		or not dollarTextLabel:IsA(
			"TextLabel"
		) then

		return nil

	end


	if not pumpkinHeadingTextLabel
		or not pumpkinHeadingTextLabel:IsA(
			"TextLabel"
		) then

		return nil

	end


	return {

		Frame =
			frame,

		PumpkinImageLabel =
			pumpkinImageLabel,

		OneInTextLabel =
			oneInTextLabel,

		DollarTextLabel =
			dollarTextLabel,

		PumpkinHeadingTextLabel =
			pumpkinHeadingTextLabel,
	}

end


--==================================================
-- UPDATE ONE INDEX ENTRY
--==================================================

local function UpdateEntry(
	pumpkinId
)

	local entry = indexFrames[pumpkinId]


	if not entry then

		return

	end


	local pumpkinInfo =
		PumpkinConfig.GetPumpkin(
			pumpkinId
		)


	if not pumpkinInfo then

		return

	end


	--==================================================
	-- ICON
	--==================================================

	entry.PumpkinImageLabel.Image =
		pumpkinInfo.Icon
		or ""


	--==================================================
	-- PERMANENT ODDS LABEL
	--==================================================

	local oneIn =
		pumpkinInfo.BaseOneIn
		or 0


	entry.OneInTextLabel.Text =
		"1/"
		.. CompactNumber(
			oneIn
		)


	--==================================================
	-- MONEY PER SECOND
	--==================================================

	local moneyPerSecond =
		pumpkinInfo.MoneyPerSecond
		or 0


	entry.DollarTextLabel.Text =
		CompactNumber(
			moneyPerSecond
		)
		.. "/s"


	--==================================================
	-- UNLOCKED
	--==================================================

	if unlockedPumpkins[
		pumpkinId
		] == true then

		entry.PumpkinHeadingTextLabel.Text =
			pumpkinInfo.DisplayName
			or pumpkinId


		-- Normal image colors.

		entry.PumpkinImageLabel.ImageColor3 =
			Color3.new(
				1,
				1,
				1
			)


		return

	end


	--==================================================
	-- LOCKED
	--==================================================

	entry.PumpkinHeadingTextLabel.Text =
		"???"


	-- Keep the actual pumpkin image but completely
	-- black it out.

	entry.PumpkinImageLabel.ImageColor3 =
		Color3.new(
			0,
			0,
			0
		)

end


--==================================================
-- UPDATE ENTIRE INDEX
--==================================================

local function UpdateAllEntries()

	for _, pumpkinId in ipairs(
		PumpkinConfig.Order
		) do

		UpdateEntry(
			pumpkinId
		)

	end

end


--==================================================
-- BUILD INDEX
--==================================================

local function BuildIndex()

	local frames =
		GetIndexFrames()


	--==================================================
	-- CHECK FRAME COUNT
	--==================================================

	if #frames
		< #PumpkinConfig.Order then

		warn(
			"[PumpkinIndexController] Not enough frames.",
			"Frames:",
			#frames,
			"Pumpkins:",
			#PumpkinConfig.Order
		)

	end


	--==================================================
	-- MATCH CONFIG TO FRAMES
	--==================================================

	for index, pumpkinId in ipairs(
		PumpkinConfig.Order
		) do

		local frame =
			frames[index]


		if not frame then

			break

		end


		local references =
			GetFrameReferences(
				frame
			)


		if references then

			indexFrames[pumpkinId] =references

		else

			warn(
				"[PumpkinIndexController] Missing UI objects in index frame:",
				index
			)

		end

	end


	UpdateAllEntries()

end


--==================================================
-- LOAD PLAYER INDEX
--==================================================

local function LoadIndex()

	local success,
		result =
		pcall(
			function()

				return GetPumpkinIndex
				:InvokeServer()

			end
		)


	if not success then

		warn(
			"[PumpkinIndexController] Could not retrieve Pumpkin Index."
		)


		return

	end


	if type(result)
		~= "table" then

		return

	end


	unlockedPumpkins =
		result


	UpdateAllEntries()

end


--==================================================
-- OPEN INDEX
--==================================================

local function OpenIndex()

	pumpkinIndexFrame.Visible =
		true


	-- Refresh whenever the player opens it.

	LoadIndex()

end


--==================================================
-- CLOSE INDEX
--==================================================

local function CloseIndex()

	pumpkinIndexFrame.Visible =
		false

end

--==================================================
-- INDEX ICON ANIMATION
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


local indexIconScale =
	indexImageLabel:FindFirstChild(
		"ButtonScale"
	)


if not indexIconScale then

	indexIconScale =
		Instance.new(
			"UIScale"
		)


	indexIconScale.Name =
		"ButtonScale"


	indexIconScale.Scale =
		NORMAL_SCALE


	indexIconScale.Parent =
		indexImageLabel

end


local function TweenIndexIcon(
	targetScale,
	duration
)

	TweenService:Create(

		indexIconScale,

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
-- INDEX ICON INPUT
--==================================================

-- IndexImageLabel is an ImageLabel rather than
-- an ImageButton, so Active must be enabled.

indexImageLabel.Active =
	true


--==================================================
-- HOVER IN
--==================================================

indexImageLabel.MouseEnter:Connect(
	function()

		TweenIndexIcon(
			HOVER_SCALE,
			HOVER_TIME
		)

	end
)


--==================================================
-- HOVER OUT
--==================================================

indexImageLabel.MouseLeave:Connect(
	function()

		TweenIndexIcon(
			NORMAL_SCALE,
			HOVER_TIME
		)

	end
)


--==================================================
-- CLICK / TOUCH DOWN
--==================================================

indexImageLabel.InputBegan:Connect(
	function(input)

		if input.UserInputType
			~= Enum.UserInputType.MouseButton1
			and input.UserInputType
			~= Enum.UserInputType.Touch then

			return

		end


		TweenIndexIcon(
			CLICK_SCALE,
			CLICK_TIME
		)


		OpenIndex()

	end
)


--==================================================
-- CLICK / TOUCH RELEASE
--==================================================

indexImageLabel.InputEnded:Connect(
	function(input)

		if input.UserInputType
			~= Enum.UserInputType.MouseButton1
			and input.UserInputType
			~= Enum.UserInputType.Touch then

			return

		end


		TweenIndexIcon(
			HOVER_SCALE,
			CLICK_TIME
		)

	end
)

--==================================================
-- EXIT BUTTON
--==================================================

exitButton.Activated:Connect(
	function()

		CloseIndex()

	end
)


--==================================================
-- SERVER UNLOCKED A NEW PUMPKIN
--==================================================

PumpkinIndexUpdated.OnClientEvent:Connect(
	function(
		pumpkinId
	)

		if type(pumpkinId)
			~= "string" then

			return

		end


		unlockedPumpkins[pumpkinId] = true


		UpdateEntry(
			pumpkinId
		)

	end
)


--==================================================
-- INITIAL STATE
--==================================================

pumpkinIndexFrame.Visible =
	false


--==================================================
-- BUILD
--==================================================

BuildIndex()


--==================================================
-- INITIAL LOAD
--==================================================

task.spawn(
	function()

		LoadIndex()

	end
)
