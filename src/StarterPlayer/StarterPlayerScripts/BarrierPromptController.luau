--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

--==================================================
-- REFERENCES
--==================================================

local player = Players.LocalPlayer
local Plots = workspace:WaitForChild("Plots")

--==================================================
-- SETTINGS
--==================================================

local UNLOCK_PROMPT_NAME = "UnlockBasePrompt"

--==================================================
-- RUNTIME
--==================================================

local watchedPrompts = {}

--==================================================
-- FIND PLOT FROM PROMPT
--==================================================

local function FindPromptPlot(prompt)
	if not prompt then
		return nil
	end

	local current = prompt.Parent

	while current and current ~= workspace do
		if current.Parent == Plots then
			return current
		end

		current = current.Parent
	end

	return nil
end

--==================================================
-- IS OWN PLOT
--==================================================

local function IsOwnPlot(plot)
	if not plot then
		return false
	end

	return plot:GetAttribute("OwnerUserId") == player.UserId
end

--==================================================
-- APPLY LOCAL PROMPT VISIBILITY
--==================================================

local function ApplyPromptVisibility(prompt)
	if not prompt or not prompt.Parent then
		return
	end

	if prompt.Name ~= UNLOCK_PROMPT_NAME then
		return
	end

	local plot = FindPromptPlot(prompt)

	if not plot then
		return
	end

	-- Hide Unlock Base only on THIS player's own plot.
	-- Other players still see it when the server enables it.
	if IsOwnPlot(plot) and prompt.Enabled then
		prompt.Enabled = false
	end
end

--==================================================
-- WATCH ONE PROMPT
--==================================================

local function WatchPrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return
	end

	if prompt.Name ~= UNLOCK_PROMPT_NAME then
		return
	end

	if watchedPrompts[prompt] then
		return
	end

	watchedPrompts[prompt] = true

	local plot = FindPromptPlot(prompt)

	ApplyPromptVisibility(prompt)

	-- If the server re-enables the prompt later, hide it
	-- again locally if this is still the player's own plot.
	prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
		ApplyPromptVisibility(prompt)
	end)

	if plot then
		plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			ApplyPromptVisibility(prompt)
		end)
	end

	prompt.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			watchedPrompts[prompt] = nil
		end
	end)
end

--==================================================
-- EXISTING PROMPTS
--==================================================

for _, descendant in ipairs(Plots:GetDescendants()) do
	if descendant:IsA("ProximityPrompt")
		and descendant.Name == UNLOCK_PROMPT_NAME then

		WatchPrompt(descendant)
	end
end

--==================================================
-- FUTURE PROMPTS
--==================================================

Plots.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("ProximityPrompt")
		and descendant.Name == UNLOCK_PROMPT_NAME then

		WatchPrompt(descendant)
	end
end)

--==================================================
-- LAST-MOMENT DISPLAY CHECK
--==================================================

ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt.Name ~= UNLOCK_PROMPT_NAME then
		return
	end

	WatchPrompt(prompt)
	ApplyPromptVisibility(prompt)
end)

print("[BarrierPromptController] Started")
