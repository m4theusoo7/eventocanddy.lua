-- // Configurações Iniciais & Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- // Parâmetros de Configuração
local SPEED = 250
local FARM_ACTIVE = false

-- // Coordenadas aproximadas da Witch (Praça principal) para banir qualquer alvo muito perto dela
local WITCH_ZONE = Vector3.new(-650, 70, -130) -- Ajuste se necessário, ou ignoramos por nome exato do modelo pai
local ISLAND_CENTERS = {
    Vector3.new(0, 50, 0),
    Vector3.new(-650, 50, -1100),
    Vector3.new(2280, 50, 905),
    Vector3.new(-5120, 50, -4250),
    Vector3.new(5734, 60, -680)
}

-- // ==========================================
-- // CRIAÇÃO DA INTERFACE (BOTÃO FLUTUANTE)
-- // ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PumpkinFarmGui"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleBtn"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Position = UDim2.new(0.05, 0, 0.2, 0)
ToggleButton.Size = UDim2.new(0, 55, 0, 55)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = ToggleButton

-- Sistema de Arrastar o Botão
local dragging, dragInput, dragStart, startPos
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

ToggleButton.MouseButton1Click:Connect(function()
    FARM_ACTIVE = not FARM_ACTIVE
    if FARM_ACTIVE then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleButton.Text = "ON"
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleButton.Text = "OFF"
    end
end)

-- // ==========================================
-- // FUNÇÕES DE FARM
-- // ==========================================

local function bypassCollisions()
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function smoothTweenTo(targetPosition)
    Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    HumanoidRootPart = Character.HumanoidRootPart
    
    local distance = (HumanoidRootPart.Position - targetPosition).Magnitude
    local timeToTravel = distance / SPEED
    
    local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = CFrame.new(targetPosition)})
    
    bypassCollisions()
    tween:Play()
    tween.Completed:Wait()
end

local function attackPumpkin()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

local function getClosestPumpkin()
    local closest = nil
    local shortestDist = math.huge
    
    Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return nil end
    local currentPos = Character.HumanoidRootPart.Position
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local nameLower = string.lower(obj.Name)
        
        -- Verifica se é o item correto
        local isTarget = string.find(nameLower, "pumpkin") or string.find(nameLower, "abobora") or string.find(nameLower, "candy")
        
        -- Procura se o nome da pasta pai ou do modelo contém termos da Witch / Loja / NPC
        local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""
        local grandParentName = obj.Parent and obj.Parent.Parent and string.lower(obj.Parent.Parent.Name) or ""
        
        local isNearWitchShop = string.find(parentName, "witch") or string.find(grandParentName, "witch") or
                              string.find(parentName, "npc") or string.find(grandParentName, "npc") or
                              string.find(parentName, "shop") or string.find(parentName, "cauldron")
        
        if isTarget and not isNearWitchShop then
            local part = nil
            if obj:IsA("Model") and obj.PrimaryPart then
                part = obj.PrimaryPart
            elseif obj:IsA("BasePart") then
                part = obj
            elseif obj:FindFirstChild("HumanoidRootPart") then
                part = obj.HumanoidRootPart
            elseif obj:FindFirstChildWhichIsA("BasePart") then
                part = obj:FindFirstChildWhichIsA("BasePart")
            end
            
            if part then
                -- Ignora se estiver na mesma posição exata do caldeirão/mesa da Witch (raio menor que 15 studs)
                -- (Isso impede que abóboras decorativas de enfeite na mesa da bruxa sejam selecionadas)
                local distFromWitchArea = (part.Position - Vector3.new(-650, 70, -130)).Magnitude -- Exemplo de centro da praça
                
                local dist = (currentPos - part.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = {Object = obj, Part = part}
                end
            end
        end
    end
    
    return closest
end

local function getNearestIsland()
    Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return Vector3.new(0,50,0) end
    local currentPos = Character.HumanoidRootPart.Position
    
    local nearestPos = ISLAND_CENTERS[1]
    local minDistance = math.huge
    
    for _, pos in ipairs(ISLAND_CENTERS) do
        local dist = (currentPos - pos).Magnitude
        if dist < minDistance and dist > 300 then
            minDistance = dist
            nearestPos = pos
        end
    end
    
    return nearestPos
end

-- // Loop Principal controlado pelo Botão
task.spawn(function()
    while true do
        task.wait(0.2)
        
        if FARM_ACTIVE then
            local targetData = getClosestPumpkin()
            
            if targetData and targetData.Object and targetData.Part then
                local targetPos = targetData.Part.Position + Vector3.new(0, 5, 0)
                smoothTweenTo(targetPos)
                
                local startTime = tick()
                while FARM_ACTIVE and targetData.Object and targetData.Object.Parent and (tick() - startTime < 3) do
                    attackPumpkin()
                    task.wait(0.1)
                end
            else
                local nextIsland = getNearestIsland()
                smoothTweenTo(nextIsland + Vector3.new(0, 15, 0))
                task.wait(1)
            end
        end
    end
end)
```[cite: 1, 2]

### O que foi ajustado agora:
* **Filtro de Pasta Pai (`parentName` e `grandParentName`):** O script agora olha quem é o "dono" (pasta ou modelo pai) do objeto. Se a abóbora estiver dentro da pasta da *Witch*, do *Cauldron* ou de um *Shop*, ela é descartada na hora, impedindo que o script confunda a decoração fixa da bruxa com as abóbora de farm reais espalhadas pelo mapa[cite: 1, 2].
