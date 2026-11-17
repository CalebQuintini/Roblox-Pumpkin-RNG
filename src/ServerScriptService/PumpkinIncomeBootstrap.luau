--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


--==================================================
-- MODULE
--==================================================

local PumpkinIncomeService =
	require(
		script.Parent
		:WaitForChild(
			"PumpkinIncomeService"
		)
	)


--==================================================
-- PLOTS
--==================================================

local Plots =
	workspace:WaitForChild(
		"Plots"
	)


--==================================================
-- REGISTER MODEL
--==================================================

local function TryRegisterPumpkin(
	plot,
	pumpkinModel
)

	if not pumpkinModel:IsA("Model") then

		return

	end


	-- Attributes may have just been added.
	task.defer(
		function()

			local ownerUserId =
				plot:GetAttribute(
					"OwnerUserId"
				)


			if type(ownerUserId)
				~= "number" then

				return

			end


			local player =
				Players:GetPlayerByUserId(
					ownerUserId
				)


			if not player then

				return

			end


			PumpkinIncomeService
				.RegisterPumpkin(
					player,
					pumpkinModel
				)

		end
	)

end


--==================================================
-- SETUP PLOT
--==================================================

local function SetupPlot(
	plot
)

	local placedFolder =
		plot:WaitForChild(
			"PlacedPumpkins"
		)


	-- Existing pumpkins.
	for _, pumpkinModel in ipairs(
		placedFolder:GetChildren()
		) do

		TryRegisterPumpkin(
			plot,
			pumpkinModel
		)

	end


	-- Newly placed pumpkins.
	placedFolder.ChildAdded:Connect(
		function(pumpkinModel)

			TryRegisterPumpkin(
				plot,
				pumpkinModel
			)

		end
	)

end


--==================================================
-- SETUP ALL PLOTS
--==================================================

for _, plot in ipairs(
	Plots:GetChildren()
	) do

	SetupPlot(
		plot
	)

end


--==================================================
-- INCOME LOOP
--==================================================

local previousTime =
	os.clock()


while true do

	task.wait(
		1
	)


	local now =
		os.clock()


	local elapsedTime =
		now - previousTime


	previousTime =
		now


	PumpkinIncomeService
		.ProcessIncome(
			elapsedTime
		)

end
