task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local Players = game.Players
    local Player = Players.LocalPlayer
    local TweenService = game:GetService("TweenService")
    local VirtualUser = game:GetService("VirtualUser")

    local ItemName = "Pumpkin"
    local Speed = 350
    local AttackDelay = 0.4

    local Islands = {
        [1] = Vector3.new(246, 15, 58),
        [2] = Vector3.new(-6500, 100, -4500),
        [3] = Vector3.new(1000, 20, 1500),
    }

    local CurrentIslandIndex = 1

    local function GetTargetPosition(target)
        if typeof(target) == "Vector3" then
            return target
        elseif target:IsA("BasePart") then
            return target.Position
        elseif target:IsA("Model") then
            local success, pivot = pcall(function() return target:GetPivot().Position end)
            if success then return pivot end
            if target.PrimaryPart then return target.PrimaryPart.Position end
        end
        return nil
    end

    local function TweenTo(targetPos)
        if not targetPos then return end
        local Character = Player.Character
        if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
        local rootPart = Character.HumanoidRootPart

        local distance = (rootPart.Position - targetPos).Magnitude
        local timeTaken = distance / Speed

        local tweenInfo = TweenInfo.new(timeTaken, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end

        local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(targetPos + Vector3.new(0, 15, 0))})
        tween:Play()

        local finished = false
        local connection
        connection = tween.Completed:Connect(function()
            finished = true
            if connection then connection:Disconnect() end
        end)

        while not finished do
            task.wait()
            if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
                tween:Cancel()
                break
            end
        end

        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end

    local function Attack()
        pcall(function()
            VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    end

    local function FindItem()
        for _, descendant in ipairs(workspace:GetDescendants()) do
            if descendant.Name == ItemName then
                if descendant:IsA("Model") or descendant:IsA("BasePart") then
                    return descendant
                end
            end
        end
        return nil
    end

    print("Script do Blox Fruits iniciado com sucesso no Delta!")

    while true do
        local Character = Player.Character or Player.CharacterAdded:Wait()
        local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

        local item = FindItem()

        if not item then
            print("Item não encontrado. A viajar para a ilha " .. CurrentIslandIndex)
            local targetIsland = Islands[CurrentIslandIndex]
            TweenTo(targetIsland)
            CurrentIslandIndex = (CurrentIslandIndex % #Islands) + 1
            task.wait(3)
        else
            print("Item encontrado! A ir ter com ele...")
            local itemPos = GetTargetPosition(item)
            
            if itemPos then
                TweenTo(itemPos)
                task.wait(0.5)

                while item and item.Parent ~= nil do
                    local currentPos = GetTargetPosition(item)
                    if currentPos and Character:FindFirstChild("HumanoidRootPart") then
                        Character.HumanoidRootPart.CFrame = CFrame.new(currentPos + Vector3.new(0, 5, 0))
                    end
                    
                    Attack()
                    
                    if not item.Parent then break end
                    task.wait(AttackDelay)
                end
                print("Item recolhido/destruído com sucesso!")
            end
        end
        task.wait(0.5)
    end
end)
