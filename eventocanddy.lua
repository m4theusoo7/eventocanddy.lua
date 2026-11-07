task.wait(1)

local player = game.Players.LocalPlayer
local tweenService = game:GetService("TweenService")
local virtualUser = game:GetService("VirtualUser")

local itemName = "Pumpkin"
local speed = 350

local islands = {
    Vector3.new(246, 15, 58),
    Vector3.new(-6500, 100, -4500),
    Vector3.new(1000, 20, 1500)
}

local index = 1

while true do
    pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart", 5)
        
        if not root then return end

        local target = nil
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == itemName and (obj:IsA("BasePart") or obj:IsA("Model")) then
                target = obj
                break
            end
        end

        if not target then
            print("Item não encontrado. A mover para a ilha " .. index)
            local dest = islands[index]
            
            local dist = (root.Position - dest).Magnitude
            local info = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
            local tween = tweenService:Create(root, info, {CFrame = CFrame.new(dest + Vector3.new(0, 15, 0))})
            
            tween:Play()
            tween.Completed:Wait()
            
            index = index % #islands + 1
            task.wait(2)
        else
            print("Item encontrado! A ir até ele...")
            local pos = target:IsA("BasePart") and target.Position or target:GetPivot().Position
            
            local dist = (root.Position - pos).Magnitude
            local info = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
            local tween = tweenService:Create(root, info, {CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))})
            
            tween:Play()
            tween.Completed:Wait()

            while target and target.Parent ~= nil do
                if char:FindFirstChild("HumanoidRootPart") and target:IsA("BasePart") then
                    char.HumanoidRootPart.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
                end
                
                virtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                virtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(0.4)
            end
            print("Item recolhido!")
        end
    end)
    task.wait(0.5)
end
