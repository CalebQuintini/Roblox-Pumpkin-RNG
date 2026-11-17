--==================================================
-- SERVICES
--==================================================

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


--==================================================
-- REMOTES
--==================================================

local remotes =
	ReplicatedStorage:FindFirstChild(
		"Remotes"
	)


if not remotes then

	remotes =
		Instance.new(
			"Folder"
		)


	remotes.Name =
		"Remotes"


	remotes.Parent =
		ReplicatedStorage

end


--==================================================
-- PLAYER FEEDBACK FOLDER
--==================================================

local playerFeedbackFolder =
	remotes:FindFirstChild(
		"PlayerFeedback"
	)


if not playerFeedbackFolder then

	playerFeedbackFolder =
		Instance.new(
			"Folder"
		)


	playerFeedbackFolder.Name =
		"PlayerFeedback"


	playerFeedbackFolder.Parent =
		remotes

end


--==================================================
-- SHOW FEEDBACK REMOTE
--==================================================

local showFeedback =
	playerFeedbackFolder:FindFirstChild(
		"ShowFeedback"
	)


if not showFeedback then

	showFeedback =
		Instance.new(
			"RemoteEvent"
		)


	showFeedback.Name =
		"ShowFeedback"


	showFeedback.Parent =
		playerFeedbackFolder

end
