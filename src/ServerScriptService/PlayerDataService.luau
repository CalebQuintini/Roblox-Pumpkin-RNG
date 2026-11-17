local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

--==================================================
-- CONFIG
--==================================================
local PlayerDataTemplate = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("PlayerDataTemplate"))

--==================================================
-- SETTINGS
--==================================================
local DATASTORE_NAME = "PumpkinRNG_PlayerData_PROD_v1"
local AUTOSAVE_INTERVAL = 60
-- If another server has not refreshed a profile
-- lock for this many seconds, we assume that
-- server crashed and allow the profile to recover.
local SESSION_LOCK_TIMEOUT = 180
local MAX_RETRIES = 3

--==================================================
-- DATASTORE
--==================================================
local PlayerStore = DataStoreService:GetDataStore(DATASTORE_NAME)

--==================================================
-- SERVICE
--==================================================
local PlayerDataService = {}
-- Profiles currently loaded by THIS server.
local LoadedProfiles = {}
-- Unique identifier for this server/session.
local SERVER_SESSION_ID = game.JobId.. ":".. HttpService:GenerateGUID(false)

--==================================================
-- DEEP COPY
--==================================================
local function DeepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	local copy = {}
	for key, value in pairs(original) do
		copy[DeepCopy(key)] =
			DeepCopy(value)
	end
	return copy
end

--==================================================
-- RECONCILE DATA
--==================================================
local function ReconcileData(data, template)
	for key, defaultValue in pairs(template) do
		local currentValue =
			data[key]
		-- Missing value:
		-- copy it from the template.
		if currentValue == nil then
			data[key] =
				DeepCopy(defaultValue)
			-- Both are tables:
			-- reconcile recursively.
		elseif type(currentValue) == "table"
			and type(defaultValue) == "table" then
			ReconcileData(
				currentValue,
				defaultValue
			)
		end
	end
end

--==================================================
-- DATA MIGRATIONS
--==================================================
local Migrations = {}
-- Example:
--
-- When we eventually create version 2:
--
-- Migrations[1] = function(data)
--
--     data.SomeNewField = 0
--     data.DataVersion = 2
--
--     return data
--
-- end
local CURRENT_DATA_VERSION =
	PlayerDataTemplate.DefaultData.DataVersion

local function ApplyMigrations(data)
	local version = data.DataVersion or 1
	while version < CURRENT_DATA_VERSION do
		local migration = Migrations[version]
		if not migration then
			error(
				"Missing migration from data version "
					.. version
			)

		end
		data = migration(data)
		version = data.DataVersion
	end
	return data
end

--==================================================
-- DATASTORE KEY
--==================================================
local function GetDataKey(player)
	return "Player_"
		.. player.UserId
end

--==================================================
-- RETRY DATASTORE OPERATION
--==================================================
local function RetryOperation(callback)
	local lastError = nil
	for attempt = 1, MAX_RETRIES do
		local success, result =
			pcall(callback)
		if success then
			return true, result
		end
		lastError =
			result
		warn(
			"DataStore operation failed. Attempt:",
			attempt,
			"Error:",
			result
		)
		if attempt < MAX_RETRIES then

			task.wait(
				attempt * 2
			)
		end
	end
	return false, lastError
end

--==================================================
-- SESSION LOCK CHECK
--==================================================
local function IsSessionExpired(session)
	if not session then
		return true
	end
	local lastSeen =
		session.LastSeen
	if not lastSeen then
		return true
	end
	local elapsed =
		os.time()
	- lastSeen
	return elapsed
		>= SESSION_LOCK_TIMEOUT
end

--==================================================
-- LOAD PLAYER
--==================================================
function PlayerDataService.LoadPlayer(player)
	if LoadedProfiles[player] then
		return true
	end
	local key = GetDataKey(player)
	local loadFailedBecauseOfSession = false
	local loadedData = nil
	local success, errorMessage =
		RetryOperation(function()
			return PlayerStore:UpdateAsync(
				key,
				function(oldProfile)
					--========================================
					-- BRAND-NEW PLAYER
					--========================================
					if oldProfile == nil then
						local newData = DeepCopy(PlayerDataTemplate.DefaultData)
						local newProfile = {
							Data = newData,
							Session = {
								Id = SERVER_SESSION_ID,
								LastSeen =
								os.time(),
							},
						}

						loadedData = DeepCopy(newData)
						return newProfile
					end

					--========================================
					-- EXISTING PROFILE
					--========================================

					local existingSession = oldProfile.Session

					-- Another live server owns the profile.
					if existingSession
						and existingSession.Id
						~= SERVER_SESSION_ID
						and not IsSessionExpired(
							existingSession
						) then

						loadFailedBecauseOfSession = true

						-- Returning nil cancels the update.
						return nil

					end

					local data = oldProfile.Data

					-- Compatibility with an unexpected/
					-- partially old profile.
					if type(data) ~= "table" then
						data = DeepCopy(PlayerDataTemplate.DefaultData)
					end

					-- Apply save-format migrations.
					data = ApplyMigrations(data)
					-- Add any missing fields from
					-- the current template.
					ReconcileData(data,PlayerDataTemplate.DefaultData)

					oldProfile.Data = data

					-- Claim the profile for this server.
					oldProfile.Session = {
						Id =
						SERVER_SESSION_ID,
						LastSeen =
						os.time(),
					}

					loadedData = DeepCopy(data)
					return oldProfile
				end
			)
		end)

	if not success then
		warn(
			"Failed to load player data for",
			player.Name,
			errorMessage
		)
		return false,
			"DataStoreError"
	end

	if loadFailedBecauseOfSession then
		warn(
			"Player profile is already active:",
			player.Name
		)
		return false,
			"ProfileAlreadyLoaded"
	end

	if not loadedData then
		warn(
			"No data returned for:",
			player.Name
		)
		return false,
			"NoData"
	end

	--==================================================
	-- STORE PROFILE IN SERVER MEMORY
	--==================================================
	LoadedProfiles[player] = {
		Data =
			loadedData,

		IsSaving =
			false,
	}

	print("Loaded data for:",player.Name)

	return true
end

--==================================================
-- GET PLAYER DATA
--==================================================
function PlayerDataService.GetData(player)
	local profile = LoadedProfiles[player]

	if not profile then
		return nil
	end
	return profile.Data
end

--==================================================
-- CHECK IF DATA IS LOADED
--==================================================
function PlayerDataService.IsLoaded(player)
	return LoadedProfiles[player]
		~= nil
end

--==================================================
-- SAVE PLAYER
--==================================================
function PlayerDataService.SavePlayer(player,releaseSession)
	local profile = LoadedProfiles[player]

	if not profile then
		return false
	end

	-- Prevent two saves for the same profile
	-- running simultaneously.
	while profile.IsSaving do
		task.wait()
	end

	profile.IsSaving = true

	local key = GetDataKey(player)

	local dataToSave = DeepCopy(profile.Data)

	local lostSessionLock = false

	local success, errorMessage =
		RetryOperation(function()
			return PlayerStore:UpdateAsync(
				key,
				function(oldProfile)
					if oldProfile == nil then
						lostSessionLock = true
						return nil

					end

					local session = oldProfile.Session

					-- This server no longer owns
					-- the profile.
					if not session
						or session.Id
						~= SERVER_SESSION_ID then
						lostSessionLock = true
						return nil
					end

					oldProfile.Data = dataToSave

					if releaseSession then
						oldProfile.Session = nil
					else
						oldProfile.Session = {
							Id =
							SERVER_SESSION_ID,
							LastSeen =
							os.time(),
						}
					end
					return oldProfile
				end
			)
		end)
	profile.IsSaving = false

	if not success then
		warn(
			"Failed to save data for:",
			player.Name,
			errorMessage
		)
		return false
	end

	if lostSessionLock then
		warn(
			"Session lock lost while saving:",
			player.Name
		)
		return false
	end
	return true
end


--==================================================
-- RELEASE PLAYER
--==================================================

function PlayerDataService.ReleasePlayer(player)
	local profile = LoadedProfiles[player]

	if not profile then
		return
	end

	local success =
		PlayerDataService.SavePlayer(
			player,
			true
		)

	if not success then
		warn(
			"Final save failed for:",
			player.Name
		)
	end
	LoadedProfiles[player] = nil
end

--==================================================
-- AUTOSAVE
--==================================================
task.spawn(function()
	while true do
		task.wait(
			AUTOSAVE_INTERVAL
		)
		for player, _ in pairs(
			LoadedProfiles
			) do
			if player.Parent == Players then
				task.spawn(function()
					PlayerDataService.SavePlayer(
						player,
						false
					)
				end)
			end
		end
	end
end)


return PlayerDataService
