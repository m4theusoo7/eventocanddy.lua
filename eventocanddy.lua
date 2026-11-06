--[[
====================================================================================
    BLOX FRUITS ✦ SEA 1 ✦ HALLOWEEN PUMPKIN AUTO-FARM
    Compatible: Synapse X / KRNL / Fluxus (executor Luau)
------------------------------------------------------------------------------------
    ▸ Scans Workspace for spawned pumpkins, tweens to the nearest one,
      snaps the HumanoidRootPart on top of it to collect, then repeats forever.
    ▸ GUI: ON/OFF button + "pumpkins collected" and "distance farmed" counters.
    ▸ Anti-AFK + INSERT keybind toggles the GUI.
------------------------------------------------------------------------------------
    HOW TO FIND THE REAL PUMPKIN NAME (if the defaults below fail):
      1) Execute a Dex Explorer script
         (e.g. https://github.com/infy-ru/dex-explorer — loadstring version works
          everywhere; Synapse also has its own built-in explorer).
      2) Stand next to a pumpkin in-game and open Dex.
      3) Expand `Workspace` and look for the newly spawned instance. Blox Fruits
         usually puts it as a Model (sometimes a Part) directly under Workspace
         or a sub-folder. Note the EXACT `Name` property (e.g. "Pumpkin",
         "HalloweenPumpkin", "Halloween Pumpkin").
      4) Write that exact name inside Config.PumpkinNames below.
         (Matching is case-insensitive, so "Pumpkin" and "PUMPKIN" both work.)
====================================================================================
]]

--// =============================================================================
--// ⚙  CONFIG — change everything here, no need to touch the rest
--// =============================================================================
local Config = {
	PumpkinNames  = {                      -- Possible names of the pumpkin instance
		"Pumpkin",                         -- (use Dex Explorer to confirm the real
		"Halloween Pumpkin",               --  name — see instructions at the top)
		"HalloweenPumpkin",
	},
	TweenSpeed    = 120,                   -- Tween speed in studs per second
	CollectDelay  = 0.35,                  -- Seconds to sit on top of the pumpkin
	ToggleKey     = Enum.KeyCode.Insert,   -- Keybind to show/hide the GUI
	NearThreshold = 8,                     -- Distance to skip tween and snap instantly
	SearchDelay   = 1.0,                   -- Wait time when no pumpkin is spawned
	TouchHeight   = 2.5,                   -- Studs above the pumpkin part (touch offset)
}

--// =============================================================================
--// 🔌 SERVICES + SHORTCUTS  (GetService only — zero deprecated globals)
--// =============================================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser      = game:GetService("VirtualUser")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--// =============================================================================
--// 📦 STATE
--// =============================================================================
local Running        = false
local Collected      = 0
local DistanceFarmed = 0
local CurrentTween   = nil
local FarmThread     = nil

local UI        = nil        -- GUI references (filled in buildGui)
local refreshUI              -- forward declaration (defined after GUI build)

-- Case-insensitive name lookup table, built once from Config
local NameSet = {}
for _, name in ipairs(Config.PumpkinNames) do
	NameSet[string.lower(name)] = true
end

--// =============================================================================
--// 🎃 PUMPKIN LOGIC
--// =============================================================================

-- Returns the main BasePart of the pumpkin (works for both Model and Part)
local function getMainPart(obj)
	if obj:IsA("BasePart") then
		return obj
	elseif obj:IsA("Model") then
		return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

-- Finds the NEAREST pumpkin in Workspace. Returns (instance, distance) or (nil, nil)
local function getNearestPumpkin(hrp)
	local best, bestDist
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if NameSet[string.lower(obj.Name)] then
			local mainPart = getMainPart(obj)
			if mainPart then
				local dist = (mainPart.Position - hrp.Position).Magnitude
				if not bestDist or dist < bestDist then
					best, bestDist = obj, dist
				end
			end
		end
	end
	return best, bestDist
end

-- Tweens the HumanoidRootPart on top of the pumpkin and waits for it (or a stop)
local function tweenAndWait(hrp, target)
	local mainPart = getMainPart(target)
	if not mainPart then return false end

	local goalPos  = mainPart.Position + Vector3.new(0, Config.TouchHeight, 0)
	local distance = (goalPos - hrp.Position).Magnitude
	local duration = math.max(distance / math.max(Config.TweenSpeed, 1), 0.1)

	CurrentTween = TweenService:Create(
		hrp,
		TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(goalPos) }
	)
	CurrentTween:Play()

	-- Wait loop: exits when the tween ends, the farm is stopped,
	-- the HRP is gone (death/respawn) or the watchdog times out
	local startedAt = os.clock()
	while Running and hrp.Parent do
		if CurrentTween.PlaybackState ~= Enum.PlaybackState.Playing then break end
		if os.clock() - startedAt > duration + 5 then break end -- watchdog vs. stuck tween
		task.wait(0.05)
	end

	local completed = CurrentTween ~= nil
		and CurrentTween.PlaybackState == Enum.PlaybackState.Completed
	Running = Running and (completed or false)
	CurrentTween = nil
	return completed
end

-- Collects the pumpkin by snapping the HRP on top of it (triggers the .Touched pickup)
local function tryCollect(hrp, target, dist)
	local mainPart = getMainPart(target)
	if not mainPart then return end

	hrp.CFrame = CFrame.new(mainPart.Position + Vector3.new(0, Config.TouchHeight, 0))

	-- Extra executor-only touch trigger in case the Touched event is unreliable
	pcall(function()
		if firetouchinterest then
			firetouchinterest(hrp, mainPart, 0)
			firetouchinterest(hrp, mainPart, 1)
		end
	end)

	task.wait(Config.CollectDelay)

	-- If the pumpkin left the Workspace, the pickup succeeded → update the stats
	if Running and not target:IsDescendantOf(Workspace) then
		Collected      = Collected + 1
		DistanceFarmed = DistanceFarmed + dist
		if refreshUI then refreshUI() end
	end
end

-- Main infinite loop: check character → scan → tween → collect → repeat
local function farmLoop()
	while Running do
		-- Sanity check: must be alive with a valid HumanoidRootPart
		local character = LocalPlayer.Character
		local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
		local hrp       = character and character:FindFirstChild("HumanoidRootPart")

		if not (humanoid and humanoid.Health > 0 and hrp) then
			task.wait(0.5) -- dead / respawning / loading → wait it out
		else
			local target, dist = getNearestPumpkin(hrp)

			if not target then
				task.wait(Config.SearchDelay) -- no pumpkin right now, scan again later
			elseif dist > Config.NearThreshold then
				-- Far away → tween there properly
				if tweenAndWait(hrp, target) and Running then
					tryCollect(hrp, target, dist)
				end
			else
				-- Practically on top of it already → collect instantly
				tryCollect(hrp, target, dist)
			end
		end
	end
	if refreshUI then refreshUI() end
end

--// =============================================================================
--// 🖥  GUI
--// ==============================================================================

-- Safe parent: executor UI container → CoreGui → PlayerGui fallback
local function getGuiParent()
	local ok, ui = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		return game:GetService("CoreGui")
	end)
	if ok and typeof(ui) == "Instance" then
		return ui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

-- Anti double-execute: remove an old copy of this GUI before building a new one
local function destroyOldGui(parent)
	local old = parent:FindFirstChild("PumpkinFarmHub")
	if old then old:Destroy() end
end

-- Optional GUI protection (Synapse: syn.protogui / ScriptWare-family: protectgui)
local function protectInstance(gui)
	pcall(function()
		if protectgui then
			protectgui(gui)
		elseif syn and syn.protogui then
			syn.protogui(gui)
		end
	end)
end

local function buildGui()
	local parent = getGuiParent()
	destroyOldGui(parent)

	-- ScreenGui root ------------------------------------------------------------
	local gui = Instance.new("ScreenGui")
	gui.Name          = "PumpkinFarmHub"
	gui.ResetOnSpawn  = false
	gui.DisplayOrder  = 9999
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent        = parent

	-- Main frame ----------------------------------------------------------------
	local main = Instance.new("Frame")
	main.Name             = "Main"
	main.Size             = UDim2.fromOffset(250, 210)
	main.Position         = UDim2.new(0, 20, 0.35, 0)
	main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	main.BorderSizePixel  = 0
	main.Active           = true
	main.Parent           = gui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 8)
	mainCorner.Parent = main

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color     = Color3.fromRGB(255, 140, 0)
	mainStroke.Thickness = 1.5
	mainStroke.Parent    = main

	-- Title (also the drag handle) ----------------------------------------------
	local title = Instance.new("TextLabel")
	title.Name             = "Title"
	title.Size             = UDim2.new(1, 0, 0, 34)
	title.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	title.BorderSizePixel  = 0
	title.Font             = Enum.Font.GothamBold
	title.Text             = "🎃 PUMPKIN FARM — SEA 1"
	title.TextColor3       = Color3.fromRGB(255, 165, 60)
	title.TextSize         = 14
	title.Parent           = main

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = title

	-- Status --------------------------------------------------------------------
	local status = Instance.new("TextLabel")
	status.Name              = "Status"
	status.Position          = UDim2.new(0, 10, 0, 40)
	status.Size              = UDim2.new(1, -20, 0, 18)
	status.BackgroundTransparency = 1
	status.Font              = Enum.Font.Gotham
	status.Text              = "Status: OFF"
	status.TextColor3        = Color3.fromRGB(255, 80, 80)
	status.TextSize          = 13
	status.TextXAlignment    = Enum.TextXAlignment.Left
	status.Parent            = main

	-- ON/OFF button -------------------------------------------------------------
	local button = Instance.new("TextButton")
	button.Name             = "Toggle"
	button.Position         = UDim2.new(0, 10, 0, 64)
	button.Size             = UDim2.new(1, -20, 0, 34)
	button.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
	button.BorderSizePixel  = 0
	button.Font             = Enum.Font.GothamBold
	button.Text             = "▶  START FARM"
	button.TextColor3       = Color3.fromRGB(255, 255, 255)
	button.TextSize         = 14
	button.AutoButtonColor  = true
	button.Parent           = main

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button

	-- Stats ---------------------------------------------------------------------
	local statsCollected = Instance.new("TextLabel")
	statsCollected.Name              = "Collected"
	statsCollected.Position          = UDim2.new(0, 10, 0, 108)
	statsCollected.Size              = UDim2.new(1, -20, 0, 18)
	statsCollected.BackgroundTransparency = 1
	statsCollected.Font              = Enum.Font.Gotham
	statsCollected.TextColor3        = Color3.fromRGB(240, 240, 240)
	statsCollected.TextSize          = 13
	statsCollected.TextXAlignment    = Enum.TextXAlignment.Left
	statsCollected.Parent            = main

	local statsDistance = Instance.new("TextLabel")
	statsDistance.Name              = "Distance"
	statsDistance.Position          = UDim2.new(0, 10, 0, 130)
	statsDistance.Size              = UDim2.new(1, -20, 0, 18)
	statsDistance.BackgroundTransparency = 1
	statsDistance.Font              = Enum.Font.Gotham
	statsDistance.TextColor3        = Color3.fromRGB(240, 240, 240)
	statsDistance.TextSize          = 13
	statsDistance.TextXAlignment    = Enum.TextXAlignment.Left
	statsDistance.Parent            = main

	-- Hint ----------------------------------------------------------------------
	local hint = Instance.new("TextLabel")
	hint.Position          = UDim2.new(0, 10, 1, -22)
	hint.Size              = UDim2.new(1, -20, 0, 16)
	hint.BackgroundTransparency = 1
	hint.Font              = Enum.Font.Gotham
	hint.Text              = "[" .. Config.ToggleKey.Name .. "] — toggle GUI"
	hint.TextColor3        = Color3.fromRGB(140, 140, 150)
	hint.TextSize          = 11
	hint.TextXAlignment    = Enum.TextXAlignment.Left
	hint.Parent            = main

	UI = {
		Gui       = gui,
		 Main     = main,
		Status    = status,
		Button    = button,
		Collected = statsCollected,
		Distance  = statsDistance,
	}

	protectInstance(gui)
end

refreshUI = function()
	if not (UI and UI.Status) then return end
	if Running then
		UI.Status.Text       = "Status: RUNNING"
		UI.Status.TextColor3 = Color3.fromRGB(70, 200, 90)
		UI.Button.Text             = "■  STOP FARM"
		UI.Button.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	else
		UI.Status.Text       = "Status: OFF"
		UI.Status.TextColor3 = Color3.fromRGB(255, 80, 80)
		UI.Button.Text             = "▶  START FARM"
		UI.Button.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
	end
	UI.Collected.Text = string.format("Pumpkins collected: %d", Collected)
	UI.Distance.Text  = string.format("Distance farmed: %.0f studs", DistanceFarmed)
end

--// =============================================================================
--// 🎮 CONTROLS: start / stop / toggle / keybind
--// =============================================================================
local function stopFarm()
	Running = false
	if CurrentTween then
		CurrentTween:Cancel() -- abort any in-flight teleport instantly
		CurrentTween = nil
	end
	if FarmThread then
		pcall(task.cancel, FarmThread)
		FarmThread = nil
	end
end

local function startFarm()
	if Running then return end
	Running    = true
	FarmThread = task.spawn(farmLoop)
end

local function toggleFarm()
	if Running then stopFarm() else startFarm() end
	refreshUI()
end

-- INSERT keybind: show/hide the GUI (ignores keys the game consumed)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Config.ToggleKey and UI and UI.Main then
		UI.Main.Visible = not UI.Main.Visible
	end
end)

--// =============================================================================
--// 🛡  ANTI-AFK (auto-dismisses the Roblox "are you still there?" popup)
--// =============================================================================
LocalPlayer.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

--// =============================================================================
--// 🚀 INIT + GUI dragging
--// =============================================================================
buildGui()
refreshUI()
UI.Button.MouseButton1Click:Connect(toggleFarm)

-- Simple drag handler (drag the GUI by its title bar — mouse + touch)
do
	local dragging, dragStart, startPos = false, nil, nil

	UI.Title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging  = true
			dragStart = input.Position
			startPos  = UI.Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			UI.Main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

print(("[PumpkinFarm] Loaded ✔  |  Press %s to toggle the GUI."):format(Config.ToggleKey.Name))
