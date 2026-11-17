
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


local SoundService =
	game:GetService(
		"SoundService"
	)


local TweenService =
	game:GetService(
		"TweenService"
	)

--==================================================
-- TOPBARPLUS
--==================================================

local TopbarPlus =
	require(
		ReplicatedStorage
		:WaitForChild("Purse")
		:WaitForChild("Packages")
		:WaitForChild("_Index")
		:WaitForChild("ryanlua_topbarplus@1.0.1")
		:WaitForChild("topbarplus")
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
-- SETTINGS REMOTES
--==================================================

local GameSettingsRemotes =
	ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild("GameSettings")


local GetSettings =
	GameSettingsRemotes:WaitForChild(
		"GetSettings"
	)


local SaveSettings =
	GameSettingsRemotes:WaitForChild(
		"SaveSettings"
	)


--==================================================
-- SETTINGS GUI
--==================================================

local SettingsGui =
	playerGui:WaitForChild(
		"SettingsGui"
	)


local SettingsFrame =
	SettingsGui:WaitForChild(
		"SettingsFrame"
	)


local InsideFrame =
	SettingsFrame:WaitForChild(
		"InsideFrame"
	)


--==================================================
-- EXIT BUTTON
--==================================================

local ExitImageButton =
	SettingsFrame:WaitForChild(
		"ExitImageButton"
	)


--==================================================
-- MUSIC UI
--==================================================

local MusicFrame =
	InsideFrame:WaitForChild(
		"MusicFrame"
	)


local MusicSwitch =
	MusicFrame:WaitForChild(
		"SwitchImageButton"
	)


local MusicGradient =
	MusicSwitch:WaitForChild(
		"UIGradient"
	)


local MusicText =
	MusicFrame:WaitForChild(
		"SwitchTextLabel"
	)


--==================================================
-- SOUND UI
--==================================================

local SoundFrame =
	InsideFrame:WaitForChild(
		"SoundFrame"
	)


local SoundSwitch =
	SoundFrame:WaitForChild(
		"SwitchImageButton"
	)


local SoundGradient =
	SoundSwitch:WaitForChild(
		"UIGradient"
	)


local SoundText =
	SoundFrame:WaitForChild(
		"SwitchTextLabel"
	)


--==================================================
-- BUTTON ANIMATION SETTINGS
--==================================================

-- How much larger the button becomes while hovered.

local HOVER_SCALE =
	1.08


-- How much smaller the button becomes when clicked.

local CLICK_SCALE =
	0.92


-- Tween duration.

local BUTTON_TWEEN_TIME =
	0.12


local BUTTON_TWEEN_INFO =
	TweenInfo.new(
		BUTTON_TWEEN_TIME,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)


--==================================================
-- COLORS
--==================================================

--==================================================
-- RED
--==================================================

-- Setting is currently ON.
--
-- Button says OFF because pressing it
-- will turn that setting OFF.

local RED_LEFT =
	Color3.fromHex(
		"#ff5100"
	)


local RED_RIGHT =
	Color3.fromHex(
		"#ff5100"
	)


--==================================================
-- GREEN
--==================================================

-- Setting is currently OFF.
--
-- Button says ON because pressing it
-- will turn that setting ON.

local GREEN_LEFT =
	Color3.fromHex(
		"#b7ff00"
	)


local GREEN_RIGHT =
	Color3.fromHex(
		"#11ff00"
	)


--==================================================
-- MUSIC ASSETS
--==================================================

local Assets =
	ReplicatedStorage:WaitForChild(
		"Assets"
	)


local SoundFolder =
	Assets:WaitForChild(
		"Sounds"
	)


local Music1Template =
	SoundFolder:WaitForChild(
		"Music1"
	)


local Music2Template =
	SoundFolder:WaitForChild(
		"Music2"
	)


--==================================================
-- CREATE LOCAL MUSIC
--==================================================

local Music1 =
	Music1Template:Clone()


Music1.Name =
	"GameMusic1"


Music1.Looped =
	false


Music1.Parent =
	SoundService


local Music2 =
	Music2Template:Clone()


Music2.Name =
	"GameMusic2"


Music2.Looped =
	false


Music2.Parent =
	SoundService


local Playlist =
	{
		Music1,
		Music2,
	}


--==================================================
-- CURRENT SETTINGS
--==================================================

local musicEnabled =
	true


local soundEnabled =
	true


--==================================================
-- ORIGINAL SOUND VOLUMES
--==================================================

local OriginalSoundVolumes =
	setmetatable(
		{},

		{
			__mode = "k",
		}
	)


--==================================================
-- BUTTON SCALE OBJECTS
--==================================================

-- We use UIScale rather than changing the actual
-- Size property.
--
-- This is important because it means your exact
-- Studio Size and Position remain untouched.

local ButtonScales =
	{}


--==================================================
-- GET / CREATE BUTTON UISCALE
--==================================================

local function GetButtonScale(
	button
)

	local existingScale = ButtonScales[button]


	if existingScale then

		return existingScale

	end


	local uiScale =
		button:FindFirstChild(
			"SettingsButtonScale"
		)


	if not uiScale then

		uiScale =
			Instance.new(
				"UIScale"
			)


		uiScale.Name =
			"SettingsButtonScale"


		uiScale.Scale =
			1


		uiScale.Parent =
			button

	end


	ButtonScales[button] = uiScale


	return uiScale

end


--==================================================
-- TWEEN BUTTON SCALE
--==================================================

local function TweenButtonScale(
	button,
	targetScale
)

	local uiScale =
		GetButtonScale(
			button
		)


	TweenService:Create(
		uiScale,
		BUTTON_TWEEN_INFO,
		{
			Scale =
				targetScale,
		}
	):Play()

end


--==================================================
-- SETUP BUTTON ANIMATION
--==================================================

local function SetupButtonAnimation(
	button
)

	-- Make sure UIScale exists immediately.

	GetButtonScale(
		button
	)


	--==================================================
	-- HOVER
	--==================================================

	button.MouseEnter:Connect(
		function()

			TweenButtonScale(
				button,
				HOVER_SCALE
			)

		end
	)


	--==================================================
	-- STOP HOVER
	--==================================================

	button.MouseLeave:Connect(
		function()

			TweenButtonScale(
				button,
				1
			)

		end
	)


	--==================================================
	-- MOUSE / TOUCH DOWN
	--==================================================

	button.MouseButton1Down:Connect(
		function()

			TweenButtonScale(
				button,
				CLICK_SCALE
			)

		end
	)


	--==================================================
	-- RELEASE
	--==================================================

	button.MouseButton1Up:Connect(
		function()

			-- If the mouse is still over the button,
			-- returning to hover size feels better.
			--
			-- Otherwise MouseLeave will return it to 1.

			TweenButtonScale(
				button,
				HOVER_SCALE
			)

		end
	)

end


--==================================================
-- SETUP ALL BUTTON ANIMATIONS
--==================================================

SetupButtonAnimation(
	MusicSwitch
)


SetupButtonAnimation(
	SoundSwitch
)


SetupButtonAnimation(
	ExitImageButton
)


--==================================================
-- IS MUSIC SOUND
--==================================================

local function IsMusicSound(
	sound
)

	return sound == Music1
		or sound == Music2
		or sound.Name == "GameMusic1"
		or sound.Name == "GameMusic2"

end


--==================================================
-- SET GRADIENT
--==================================================

local function SetSwitchGradient(
	gradient,
	leftColor,
	rightColor
)

	gradient.Color =
		ColorSequence.new({
			ColorSequenceKeypoint.new(
				0,
				leftColor
			),

			ColorSequenceKeypoint.new(
				1,
				rightColor
			),
		})

end


--==================================================
-- UPDATE MUSIC SWITCH VISUAL
--==================================================

local function UpdateMusicVisual()

	if musicEnabled then

		-- Music currently ON.
		--
		-- Pressing button will turn it OFF.

		SetSwitchGradient(
			MusicGradient,
			RED_LEFT,
			RED_RIGHT
		)


		MusicText.Text =
			"OFF"

	else

		-- Music currently OFF.
		--
		-- Pressing button will turn it ON.

		SetSwitchGradient(
			MusicGradient,
			GREEN_LEFT,
			GREEN_RIGHT
		)


		MusicText.Text =
			"ON"

	end

end


--==================================================
-- UPDATE SOUND SWITCH VISUAL
--==================================================

local function UpdateSoundVisual()

	if soundEnabled then

		SetSwitchGradient(
			SoundGradient,
			RED_LEFT,
			RED_RIGHT
		)


		SoundText.Text =
			"OFF"

	else

		SetSwitchGradient(
			SoundGradient,
			GREEN_LEFT,
			GREEN_RIGHT
		)


		SoundText.Text =
			"ON"

	end

end


--==================================================
-- APPLY MUSIC SETTING
--==================================================

local function ApplyMusicSetting()

	if musicEnabled then

		-- Playlist loop will handle starting music.

		return

	end


	-- Immediately stop both songs.

	for _, music in ipairs(
		Playlist
		) do

		music:Stop()

	end

end


--==================================================
-- APPLY SETTING TO ONE SOUND
--==================================================

local function ApplySoundSettingToSound(
	sound
)

	if not sound:IsA(
		"Sound"
		) then

		return

	end


	-- Music is controlled separately.

	if IsMusicSound(
		sound
		) then

		return

	end


	--==================================================
	-- SAVE ORIGINAL VOLUME
	--==================================================

	if OriginalSoundVolumes[
		sound
		] == nil then

		OriginalSoundVolumes[sound] = sound.Volume

	end


	--==================================================
	-- APPLY SETTING
	--==================================================

	if soundEnabled then

		sound.Volume = OriginalSoundVolumes[sound]

	else

		sound.Volume =
			0

	end

end


--==================================================
-- APPLY SOUND SETTING
--==================================================

local function ApplySoundSetting()

	for _, descendant in ipairs(
		game:GetDescendants()
		) do

		if descendant:IsA(
			"Sound"
			) then

			ApplySoundSettingToSound(
				descendant
			)

		end

	end

end


--==================================================
-- WATCH FUTURE SOUNDS
--==================================================

game.DescendantAdded:Connect(
	function(descendant)

		if not descendant:IsA(
			"Sound"
			) then

			return

		end


		task.defer(
			function()

				if descendant.Parent then

					ApplySoundSettingToSound(
						descendant
					)

				end

			end
		)

	end
)


--==================================================
-- LOAD SAVED SETTINGS
--==================================================

local success,
	savedSettings =
	pcall(
		function()

			return GetSettings:InvokeServer()

		end
	)


if success
	and type(savedSettings)
	== "table" then

	if type(
		savedSettings.MusicEnabled
		) == "boolean" then

		musicEnabled =
			savedSettings.MusicEnabled

	end


	if type(
		savedSettings.SoundEnabled
		) == "boolean" then

		soundEnabled =
			savedSettings.SoundEnabled

	end

else

	warn(
		"[GameSettingsClient] Could not load saved settings.",
		savedSettings
	)

end


--==================================================
-- APPLY INITIAL SETTINGS
--==================================================

UpdateMusicVisual()


UpdateSoundVisual()


ApplyMusicSetting()


ApplySoundSetting()


--==================================================
-- MUSIC SWITCH CLICKED
--==================================================

MusicSwitch.Activated:Connect(
	function()

		musicEnabled =
			not musicEnabled


		--==================================================
		-- VISUAL
		--==================================================

		UpdateMusicVisual()


		--==================================================
		-- AUDIO
		--==================================================

		ApplyMusicSetting()


		--==================================================
		-- SAVE
		--==================================================

		SaveSettings:FireServer(
			"MusicEnabled",
			musicEnabled
		)

	end
)


--==================================================
-- SOUND SWITCH CLICKED
--==================================================

SoundSwitch.Activated:Connect(
	function()

		soundEnabled =
			not soundEnabled


		--==================================================
		-- VISUAL
		--==================================================

		UpdateSoundVisual()


		--==================================================
		-- AUDIO
		--==================================================

		ApplySoundSetting()


		--==================================================
		-- SAVE
		--==================================================

		SaveSettings:FireServer(
			"SoundEnabled",
			soundEnabled
		)

	end
)


--==================================================
-- EXIT BUTTON CLICKED
--==================================================

ExitImageButton.Activated:Connect(
	function()

		--==================================================
		-- CLICK ANIMATION
		--==================================================

		TweenButtonScale(
			ExitImageButton,
			CLICK_SCALE
		)


		task.delay(
			BUTTON_TWEEN_TIME,

			function()

				--==================================================
				-- RETURN BUTTON TO NORMAL SIZE
				--==================================================

				TweenButtonScale(
					ExitImageButton,
					1
				)


				--==================================================
				-- FIND SETTINGS TOPBAR ICON
				--==================================================

				local settingsIcon =
					TopbarPlus.getIcon(
						"Settings"
					)


				--==================================================
				-- DESELECT TOPBAR ICON
				--==================================================

				if settingsIcon then

					-- Deselecting the icon automatically
					-- hides SettingsFrame because the frame
					-- is bound using bindToggleItem().

					settingsIcon:deselect(
						"ExitButton"
					)

				else

					-- Safety fallback.
					--
					-- If for some reason the topbar icon
					-- cannot be found, still close the UI.

					SettingsFrame.Visible =
						false

				end

			end
		)

	end
)


--==================================================
-- MUSIC PLAYLIST
--==================================================

task.spawn(
	function()

		while true do

			for _, music in ipairs(
				Playlist
				) do

				--==================================================
				-- WAIT UNTIL MUSIC IS ENABLED
				--==================================================

				while not musicEnabled do

					task.wait(
						0.2
					)

				end


				--==================================================
				-- PLAY
				--==================================================

				music.TimePosition =
					0


				music:Play()


				--==================================================
				-- WAIT
				--==================================================

				while music.IsPlaying
					and musicEnabled do

					task.wait(
						0.1
					)

				end


				if not musicEnabled then

					music:Stop()

				end

			end

		end

	end
)


--==================================================
-- STARTED
--==================================================

print(
	"[GameSettingsClient] Initialized.",
	"Music:",
	musicEnabled,
	"Sound:",
	soundEnabled
)
