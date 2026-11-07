local PUMPKIN_NAME = "Pumpkin"
local FLY_SPEED = 75

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer
local farmActive = false

local function equipWeapon()
    local character = localPlayer.Character
    if not character then return nil end
    
    local currentTool = character:FindFirstChildWhichIsA("Tool")
    if currentTool then return currentTool end
    
    local backpack = localPlayer:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChildWhichIsA("Tool")
        if tool then
            tool.Parent = character
            return tool
        end
    end
    return nil
end

local function moveToCFrame(targetCFrame)
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude
    local duration = distance / FLY_SPEED
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    tween.Completed:Wait()
end

local function attackTarget()
    local weapon = equipWeapon()
    if weapon then
        weapon:Activate()
    end
end

local function startFarmLoop()
    farmActive = true
    print("Farm Started")
    
    while farmActive do
        local foundItem = false
        
        for _, object in pairs(workspace:GetDescendants()) do
            if not farmActive then break end
            
            if string.find(object.Name:lower(), "pumpkin") or string.find(object.Name:lower(), "candy") then
                local targetPart = object:IsA("BasePart") and object or object:FindFirstChildWhichIsA("BasePart")
                
                if targetPart and targetPart.Parent then
                    foundItem = true
                    
                    while farmActive and targetPart and targetPart:IsDescendantOf(workspace) do
                        moveToCFrame(targetPart.CFrame * CFrame.new(0, 0.5, 0))
                        attackTarget()
                        task.wait(0.1)
                    end
                end
            end
        end
        
        if not foundItem then
            task.wait(3)
        end
    end
end

localPlayer.Chatted:Connect(function(message)
    local cmd = message:lower()
    if cmd == "!farm" then
        if not farmActive then
            task.spawn(startFarmLoop)
        else
            farmActive = false
            print("Farm Disabled")
        end
    elseif cmd == "!stop" then
        farmActive = false
        print("Farm Stopped")
    end
end)
