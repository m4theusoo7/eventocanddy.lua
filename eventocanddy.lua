-- Serviços necessários
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local FARM_ACTIVE = true
local TRAVEL_SPEED = 250 -- Velocidade de voo entre as ilhas (studs por segundo)
local HIT_DELAY = 0.15   -- Velocidade dos cliques para quebrar

-- Função para encontrar a abóbora mais próxima (independente da ilha)
local function getNearestPumpkin()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local rootPart = character.HumanoidRootPart
    local nearest = nil
    local shortestDistance = math.huge
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("pumpkin") or obj.Name:lower():find("abobora") then
            local part = obj:IsA("Model") and obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local distance = (rootPart.Position - part.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearest = part
                end
            end
        end
    end
    
    return nearest
end

-- Função para equipar a ferramenta (soco/estilo de luta)
local function equipTool()
    local character = LocalPlayer.Character
    if not character then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            local tool = backpack:FindFirstChildOfClass("Tool")
            if tool then
                character.Humanoid:EquipTool(tool)
            end
        end
    end
end

-- Função para simular o clique que quebra a abóbora
local function hitPumpkin()
    local vim = VirtualInputManager
    local viewportSize = Workspace.CurrentCamera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2
    
    -- Simula clique do mouse
    vim:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.05)
    vim:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
end

-- Função de voo suave (Tween) para viajar entre ilhas
local function flyToTarget(targetCFrame)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = character.HumanoidRootPart
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude
    local timeToTravel = distance / TRAVEL_SPEED
    
    -- Se estiver muito perto, apenas teletransporta
    if distance < 30 then
        rootPart.CFrame = targetCFrame
        return
    end
    
    local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    return tween
end

-- Loop principal de Farm entre Ilhas
task.spawn(function()
    while FARM_ACTIVE do
        task.wait(0.1)
        
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local targetPumpkin = getNearestPumpkin()
            
            if targetPumpkin then
                -- 1. Viaja até a ilha/local onde a abóbora está
                local destination = targetPumpkin.CFrame + Vector3.new(0, 3, 0)
                local currentTween = flyToTarget(destination)
                
                -- Aguarda chegar na abóbora
                if currentTween then
                    while currentTween.PlaybackState == Enum.PlaybackState.Playing and targetPumpkin.Parent and FARM_ACTIVE do
                        task.wait(0.05)
                    end
                end
                
                -- 2. Fica batendo até quebrar a abóbora atual
                while targetPumpkin and targetPumpkin.Parent and FARM_ACTIVE do
                    equipTool()
                    
                    -- Mantém o personagem colado na abóbora
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        rootPart.CFrame = targetPumpkin.CFrame + Vector3.new(0, 2, 0)
                    end
                    
                    -- Ataca
                    hitPumpkin()
                    
                    task.wait(HIT_DELAY)
                    
                    -- Se a abóbora quebrou, sai do loop para procurar a próxima
                    if not targetPumpkin.Parent then
                        break
                    end
                end
            end
        end
    end
end)
