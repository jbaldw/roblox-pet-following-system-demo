local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local NeedsConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("NeedsConfig"))

-- Helper: Create the floating overhead display programmatically
local function createNeedBillboard(adorneePart)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NeedBillboard"
	billboard.Adornee = adorneePart
	billboard.Size = UDim2.new(0, 60, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0) -- Floats 2.5 studs above the cat
	billboard.AlwaysOnTop = true                    -- Visible through thin walls/grass
	billboard.Enabled = false                       -- Hidden by default
	billboard.Parent = adorneePart

	-- Background bubble
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	background.BackgroundTransparency = 0.1
	background.Parent = billboard

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0) -- Circular bubble
	corner.Parent = background

	-- Text or Icon Label
	local taskText = Instance.new("TextLabel")
	taskText.Name = "TaskLabel"
	taskText.Size = UDim2.new(1, 0, 1, 0)
	taskText.BackgroundTransparency = 1
	taskText.Font = Enum.Font.FredokaOne
	taskText.TextScaled = true
	taskText.TextColor3 = Color3.fromRGB(50, 50, 50)
	taskText.Text = ""
	taskText.Parent = background

	return billboard, taskText
end

-- The listener function that observes the pet
local function listenToPet(petModel)
	local primaryPart = petModel.PrimaryPart or petModel:WaitForChild("PrimaryPart", 5)
	if not primaryPart then
		warn("Cannot attach UI: Pet has no PrimaryPart!")
		return
	end

	local billboard, taskLabel = createNeedBillboard(primaryPart)

	-- Update UI function based on the current attribute state
	local function updateDisplay()
		local currentNeed = petModel:GetAttribute("CurrentNeed")

		if currentNeed and currentNeed ~= "" then
			local taskData = NeedsConfig.Tasks[currentNeed]
			local displayName = taskData and taskData.DisplayName or currentNeed

			taskLabel.Text = displayName
			billboard.Enabled = true
		else
			-- Pet is satisfied or idle
			billboard.Enabled = false
			taskLabel.Text = ""
		end
	end

	-- 1. Check once immediately in case the pet already has a need on spawn
	updateDisplay()

	-- 2. Listen for future changes without running a frame loop
	petModel:GetAttributeChangedSignal("CurrentNeed"):Connect(updateDisplay)
end

-- Hook: Watch Workspace for this specific player's pet
local expectedPetName = player.Name .. "_Pet"

-- Check if the pet already exists in Workspace
local existingPet = workspace:FindFirstChild(expectedPetName)
if existingPet then
	listenToPet(existingPet)
end

-- Listen for the pet spawning or respawning later
workspace.ChildAdded:Connect(function(child)
	if child.Name == expectedPetName and child:IsA("Model") then
		listenToPet(child)
	end
end)

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local rewardEffectEvent = ReplicatedStorage:WaitForChild("RewardEffect")

-- 1. Create the coin chime sound
local coinSound = Instance.new("Sound")
coinSound.Name = "CoinChime"
-- A pleasant, free coin pickup chime from the Creator Store
coinSound.SoundId = "rbxassetid://5153734608"
coinSound.Volume = 0.6
coinSound.Parent = SoundService

local function spawnFloatingReward(amount, position)
	-- Play sound locally
	SoundService:PlayLocalSound(coinSound)

	-- Temporary invisible anchor part in Workspace for the BillboardGui
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Position = position + Vector3.new(0, 1.5, 0)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Parent = workspace

	-- Floating Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CoinPopup"
	billboard.Adornee = anchor
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = anchor

	-- "+XX Coins" Text Label
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = "+" .. tostring(amount) .. " Coins!"
	label.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	label.TextStrokeColor3 = Color3.fromRGB(80, 50, 0) -- Dark brown outline
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Parent = billboard

	-- 2. Animate: Float up 3.5 studs and fade out over 0.8 seconds
	local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	local offsetTween = TweenService:Create(billboard, tweenInfo, {
		StudsOffset = Vector3.new(0, 3.5, 0)
	})
	local textFadeTween = TweenService:Create(label, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})

	offsetTween:Play()
	textFadeTween:Play()

	-- 3. Garbage Collection: delete anchor and billboard once animation finishes
	task.delay(0.85, function()
		anchor:Destroy()
	end)
end

-- Connect to the server event
rewardEffectEvent.OnClientEvent:Connect(function(amount, position)
	spawnFloatingReward(amount, position)
end)