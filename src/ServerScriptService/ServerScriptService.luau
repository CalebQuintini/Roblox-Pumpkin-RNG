--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


--==================================================
-- MODULES
--==================================================

local PlotService =
	require(
		script.Parent
		:WaitForChild("PlotService")
	)


local PumpkinSellService =
	require(
		script.Parent
		:WaitForChild("PumpkinSellService")
	)


--==================================================
-- WORLD
--==================================================

local Plots =
	workspace:WaitForChild(
		"Plots"
	)


--==================================================
-- SETTINGS
--==================================================

local SELL_COOLDOWN =
	0.2


--==================================================
-- STATE
--==================================================

local lastSellTime =
	{}


--==================================================
-- CONNECT TRASH CAN
--==================================================

local function SetupTrashCan(
	plot
)

	local rollArea =
		plot:FindFirstChild(
			"RollArea"
		)


	if not rollArea then

		warn(
			"[PumpkinSellServer] Missing RollArea:",
			plot.Name
		)


		return

	end


	local sellTrashMesh =
		rollArea:FindFirstChild(
			"SellTrashMesh"
		)


	if not sellTrashMesh then

		warn(
			"[PumpkinSellServer] Missing SellTrashMesh:",
			plot.Name
		)


		return

	end


	local trashCan =
		sellTrashMesh:FindFirstChild(
			"TrashCan",
			true
		)


	if not trashCan then

		warn(
			"[PumpkinSellServer] Missing TrashCan:",
			plot.Name
		)


		return

	end


	local prompt =
		trashCan:FindFirstChildOfClass(
			"ProximityPrompt"
		)


	if not prompt then

		warn(
			"[PumpkinSellServer] Missing ProximityPrompt:",
			plot.Name
		)


		return

	end


	--==================================================
	-- PROMPT SETTINGS
	--==================================================

	prompt.ActionText =
		"Sell Held Pumpkin"


	prompt.ObjectText =
		"Trash"


	--==================================================
	-- PROMPT TRIGGERED
	--==================================================

	prompt.Triggered:Connect(
		function(player)

			--==================================================
			-- VERIFY PLAYER OWNS THIS PLOT
			--==================================================

			-- Never trust the client or the prompt.
			--
			-- Even if another player's client somehow
			-- activates this prompt, the server rejects it.

			local playerPlot =
				PlotService.GetPlayerPlot(
					player
				)


			if playerPlot
				~= plot then

				return

			end


			if plot:GetAttribute(
				"OwnerUserId"
				) ~= player.UserId then

				return

			end


			--==================================================
			-- RATE LIMIT
			--==================================================

			local now =
				os.clock()


			local previous =
				lastSellTime[
			player
			]
				or 0


			if now - previous
				< SELL_COOLDOWN then

				return

			end


			lastSellTime[
			player
			] =
				now


			--==================================================
			-- SELL
			--==================================================

			local success,
			result =
				PumpkinSellService
				.SellHeldPumpkin(
					player
				)


			--==================================================
			-- NOTHING HELD
			--==================================================

			if not success then

				-- As requested:
				--
				-- If the player isn't holding a pumpkin,
				-- nothing happens.

				if result
					== "NoHeldPumpkin" then

					return

				end


				warn(
					"[PumpkinSellServer] Sell failed:",
					player.Name,
					result
				)


				return

			end


			--==================================================
			-- DEBUG
			--==================================================

			print(
				player.Name,
				"sold",
				result.PumpkinId,
				"InstanceId:",
				result.InstanceId,
				"for $",
				result.SellValue
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

	SetupTrashCan(
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

				SetupTrashCan(
					plot
				)

			end
		)

	end
)


--==================================================
-- PLAYER CLEANUP
--==================================================

Players.PlayerRemoving:Connect(
	function(player)

		lastSellTime[
		player
		] =
			nil

	end
)
