local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	-- "leaderstats" is a reserved folder name that Roblox displays on the top-right scoreboard
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats
end)