-- // Configurações Iniciais & Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- // Parâmetros de Configuração
local SPEED = 250
local FARM_ACTIVE = false

-- // Lista de principais ilhas do Blox Fruits para transição
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

UserInputService.InputChanged:Connect(function(input)
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
-- // FUNÇÕES DE FARM E BUSCA PRECISA
-- // ==========================================

local function bypassCollisions()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function smoothTweenTo(targetPosition)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local distance = (hrp.Position - targetPosition).Magnitude
    local timeToTravel = distance / SPEED
    
    local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPosition)})
    
    bypassCollisions()
    tween:Play()
    tween.Completed:Wait()
end

-- SOLUÇÃO DEFINITIVA: Intercepta e executa o Framework de Ataque Real do Blox Fruits
local function executeCombatAttack()
    -- Método Principal: Invoca o Módulo de Combate Interno do jogo ativo nos scripts locais do seu jogador
    pcall(function()
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if playerScripts then
            local combatFramework = playerScripts:FindFirstChild("CombatFramework")
            if combatFramework and combatFramework:IsA("ModuleScript") then
                local framework = require(combatFramework)
                if framework and framework.activeController then
                    -- Força o gatilho da função de ataque da sua arma/estilo de luta equipada
                    framework.activeController.attack()
                end
            end
        end
    end)

    -- Método Secundário (Bypass): Envia diretamente os pacotes de rede se o framework local estiver ofuscado
    pcall(function()
        local netRemotes = ReplicatedStorage:FindFirstChild("Remotes")
        if netRemotes then
            local validator = netRemotes:FindFirstChild("Validator") or netRemotes:FindFirstChild("Click")
            if validator and validator:IsA("RemoteEvent") then
                -- Dispara o evento de ataque contornando completamente a tela e simulando dano Melee legítimo
                validator:FireServer("Melee", 1)
            end
        end
    end)
end

local function getClosestPumpkin()
    local closest = nil
    local shortestDist = math.huge
    
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local currentPos = hrp.Position
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nameLower = string.lower(obj.Name)
            
            if (string.find(nameLower, "pumpkin") or string.find(nameLower, "abobora") or string.find(nameLower, "candy")) then
                local fullNameLower = string.lower(obj:GetFullName())
                
                local isInvalid = string.find(fullNameLower, "witch") or 
                                  string.find(fullNameLower, "npc") or 
                                  string.find(fullNameLower, "shop") or 
                                  string.find(fullNameLower, "wall") or 
                                  string.find(fullNameLower, "door") or 
                                  string.find(fullNameLower, "house") or
                                  string.find(fullNameLower, "cauldron")
                
                if not isInvalid and obj.Size.Magnitude < 10 then
                    local dist = (currentPos - obj.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = {Object = obj, Part = obj}
                    end
                end
            end
        end
    end
    
    return closest
end

local function getNearestIsland()
    local char = LocalPlayer.Character
    if not char then return ISLAND_CENTERS[1] end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return ISLAND_CENTERS[1] end
    local currentPos = hrp.Position
    
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
        task.wait(0.05) -- Resposta ultra rápida de verificação
        
        if FARM_ACTIVE then
            local targetData = getClosestPumpkin()
            
            if targetData and targetData.Object and targetData.Part and targetData.Object.Parent then
                -- Posiciona perfeitamente acima sem colidir na abóbora
                local targetPos = targetData.Part.Position + Vector3.new(0, 2.5, 0)
                smoothTweenTo(targetPos)
                
                local startTime = tick()
                while FARM_ACTIVE and targetData.Object and targetData.Object.Parent and (tick() - startTime < 4) do
                    -- Trava a posição para evitar empurrões da física
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = CFrame.new(targetPos)
                    end
                    
                    executeCombatAttack() -- Executa o ataque via backend do jogo
                    task.wait(0.1) -- Ritmo rápido e otimizado de socos
                end
            else
                local nextIsland = getNearestIsland()
                smoothTweenTo(nextIsland + Vector3.new(0, 15, 0))
                task.wait(1)
            end
        end
    end
end)
