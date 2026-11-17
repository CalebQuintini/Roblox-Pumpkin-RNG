--==================================================
-- SERVICES
--==================================================

local DataStoreService =
	game:GetService(
		"DataStoreService"
	)


local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)


--==================================================
-- DATA STORE
--==================================================

local SettingsDataStore =
	DataStoreService:GetDataStore(
		"PumpkinRNG_GameSettings_v1"
	)


--==================================================
-- DEFAULT SETTINGS
--==================================================

-- true means the audio category is currently enabled.

local DEFAULT_SETTINGS =
	{
		MusicEnabled = true,
		SoundEnabled = true,
	}


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage:FindFirstChild(
		"Remotes"
	)


if not Remotes then

	Remotes =
		Instance.new(
			"Folder"
		)


	Remotes.Name =
		"Remotes"


	Remotes.Parent =
		ReplicatedStorage

end


local GameSettingsFolder =
	Remotes:FindFirstChild(
		"GameSettings"
	)


if not GameSettingsFolder then

	GameSettingsFolder =
		Instance.new(
			"Folder"
		)


	GameSettingsFolder.Name =
		"GameSettings"


	GameSettingsFolder.Parent =
		Remotes

end


--==================================================
-- GET SETTINGS REMOTE
--==================================================

local GetSettings =
	GameSettingsFolder:FindFirstChild(
		"GetSettings"
	)


if not GetSettings then

	GetSettings =
		Instance.new(
			"RemoteFunction"
		)


	GetSettings.Name =
		"GetSettings"


	GetSettings.Parent =
		GameSettingsFolder

end


--==================================================
-- SAVE SETTINGS REMOTE
--==================================================

local SaveSettings =
	GameSettingsFolder:FindFirstChild(
		"SaveSettings"
	)


if not SaveSettings then

	SaveSettings =
		Instance.new(
			"RemoteEvent"
		)


	SaveSettings.Name =
		"SaveSettings"


	SaveSettings.Parent =
		GameSettingsFolder

end


--==================================================
-- RUNTIME CACHE
--==================================================

local PlayerSettings =
	{}


--==================================================
-- COPY DEFAULT SETTINGS
--==================================================

local function CreateDefaultSettings()

	return {
		MusicEnabled =
			DEFAULT_SETTINGS.MusicEnabled,

		SoundEnabled =
			DEFAULT_SETTINGS.SoundEnabled,
	}

end


--==================================================
-- LOAD SETTINGS
--==================================================

local function LoadSettings(
	player
)

	local settings =
		CreateDefaultSettings()


	local success,
		savedData =
		pcall(
			function()

				return SettingsDataStore:GetAsync(
					tostring(
						player.UserId
					)
				)

			end
		)


	if success
		and type(savedData)
		== "table" then

		if type(
			savedData.MusicEnabled
			) == "boolean" then

			settings.MusicEnabled =
				savedData.MusicEnabled

		end


		if type(
			savedData.SoundEnabled
			) == "boolean" then

			settings.SoundEnabled =
				savedData.SoundEnabled

		end

	elseif not success then

		warn(
			"[GameSettingsPersistenceServer] Could not load settings for",
			player.Name
		)

	end


	PlayerSettings[player] = settings


	return settings

end


--==================================================
-- SAVE SETTINGS
--==================================================

local function SavePlayerSettings(
	player
)

	local settings = PlayerSettings[player]


	if not settings then

		return

	end


	local dataToSave =
		{
			MusicEnabled =
			settings.MusicEnabled,

			SoundEnabled =
			settings.SoundEnabled,
		}


	local success,
		errorMessage =
		pcall(
			function()

				SettingsDataStore:SetAsync(
					tostring(
						player.UserId
					),

					dataToSave
				)

			end
		)


	if not success then

		warn(
			"[GameSettingsPersistenceServer] Could not save settings for",
			player.Name,
			errorMessage
		)

	end

end


--==================================================
-- GET SETTINGS
--==================================================

GetSettings.OnServerInvoke =
	function(player)

		local settings = PlayerSettings[player]


		if not settings then

			settings = LoadSettings(player)

		end


		-- Return a copy.

		return {
			MusicEnabled =
			settings.MusicEnabled,

			SoundEnabled =
			settings.SoundEnabled,
		}

	end


--==================================================
-- SAVE SETTING CHANGE
--==================================================

SaveSettings.OnServerEvent:Connect(
	function(
		player,
		settingName,
		newValue
	)

		--==================================================
		-- VALIDATE
		--==================================================

		if type(newValue)
			~= "boolean" then

			return

		end


		if settingName
			~= "MusicEnabled"
			and settingName
			~= "SoundEnabled" then

			return

		end


		--==================================================
		-- GET SETTINGS
		--==================================================

		local settings = PlayerSettings[player]


		if not settings then

			settings =
				LoadSettings(
					player
				)

		end


		--==================================================
		-- UPDATE
		--==================================================

		settings[settingName] = newValue


		-- Save immediately because settings are changed
		-- infrequently.

		task.spawn(
			SavePlayerSettings,
			player
		)

	end
)


--==================================================
-- PLAYER LEAVING
--==================================================

game:GetService(
	"Players"
).PlayerRemoving:Connect(
	function(player)

		SavePlayerSettings(
			player
		)


		PlayerSettings[player] = nil

	end
)


--==================================================
-- SERVER CLOSING
--==================================================

game:BindToClose(
	function()

		for player in pairs(
			PlayerSettings
			) do

			SavePlayerSettings(
				player
			)

		end

	end
)


print(
	"[GameSettingsPersistenceServer] Started"
)
