local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NeedsConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("NeedsConfig"))

-- Ensure the RemoteEvent exists without relying on Explorer ordering
local rewardEffectEvent = ReplicatedStorage:FindFirstChild("RewardEffect")
if not rewardEffectEvent then
	rewardEffectEvent = Instance.new("RemoteEvent")
	rewardEffectEvent.Name = "RewardEffect"
	rewardEffectEvent.Parent = ReplicatedStorage
end

-- Helper: Safely resolve the 3D position of the station for visual effects
local function getStationPosition(prompt)
	local parent = prompt.Parent
	if parent:IsA("BasePart") then
		return parent.Position
	elseif parent:IsA("Model") and parent.PrimaryPart then
		return parent.PrimaryPart.Position
	end

	local childPart = parent:FindFirstChildWhichIsA("BasePart", true)
	return childPart and childPart.Position or Vector3.zero
end

-- Main interaction handler
local function onPromptTriggered(prompt, player)
	local targetNeed = prompt:GetAttribute("TargetNeed") or prompt.Parent:GetAttribute("TargetNeed")
	if not targetNeed then
		return
	end

	local pet = workspace:FindFirstChild(player.Name .. "_Pet")
	if not pet then
		return
	end

	-- Ignore trigger if pet doesn't actively have this need
	if pet:GetAttribute("CurrentNeed") ~= targetNeed then
		return
	end

	-- 1. Clear need (triggers client UI to hide automatically)
	pet:SetAttribute("CurrentNeed", "")

	-- 2. Award currency
	local taskData = NeedsConfig.Tasks[targetNeed]
	local reward = taskData and taskData.RewardCoins or 15

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins then
		coins.Value += reward
	end

	-- 3. Fire local juice/audio to the triggering player
	local stationPosition = getStationPosition(prompt)
	rewardEffectEvent:FireClient(player, reward, stationPosition)
end

-- Connect prompt listeners across the workspace
local function bindPrompt(prompt)
	prompt.Triggered:Connect(function(player)
		onPromptTriggered(prompt, player)
	end)
end

for _, descendant in ipairs(workspace:GetDescendants()) do
	if descendant:IsA("ProximityPrompt") then
		bindPrompt(descendant)
	end
end

workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("ProximityPrompt") then
		bindPrompt(descendant)
	end
end)