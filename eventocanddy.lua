-- // Configurações Iniciais & Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- // Parâmetros de Configuração
local SPEED = 250 -- Velocidade de voo/tween estável
local FARM_ACTIVE = true

-- // Lista de principais ilhas do Blox Fruits (Marinha/Mundo para referência de transição)
local ISLAND_CENTERS = {
    Vector3.new(0, 50, 0),       -- Exemplo de centro geral ou ilha inicial
    Vector3.new(-650, 50, -1100), -- Exemplo Ilha 1
    Vector3.new(2280, 50, 905),   -- Exemplo Ilha 2
    Vector3.new(-5120, 50, -4250), -- Exemplo Ilha Terceiro Sea
    Vector3.new(5734, 60, -680)
}

-- // Função para desativar colisões e evitar travar
local function bypassCollisions()
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

-- // Função de Tween suave até uma posição de destino
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

-- // Simula o clique contínuo para quebrar/coletar o item
local function attackPumpkin()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- // Encontra o Pumpkin mais próximo na ilha atual
local function getClosestPumpkin()
    local closest = nil
    local shortestDist = math.huge
    
    Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return nil end
    local currentPos = Character.HumanoidRootPart.Position
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local nameLower = string.lower(obj.Name)
        if string.find(nameLower, "pumpkin") or string.find(nameLower, "abobora") or string.find(nameLower, "candy") then
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

-- // Encontra a ilha/ponto mais próximo quando acabam os pumpkins da região
local function getNearestIsland()
    Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return Vector3.new(0,50,0) end
    local currentPos = Character.HumanoidRootPart.Position
    
    local nearestPos = ISLAND_CENTERS[1]
    local minDistance = math.huge
    
    for _, pos in ipairs(ISLAND_CENTERS) do
        local dist = (currentPos - pos).Magnitude
        if dist < minDistance and dist > 300 then -- Ignora a própria posição atual
            minDistance = dist
            nearestPos = pos
        end
    end
    
    return nearestPos
end

-- // Loop Principal de Farm Sequencial
task.spawn(function()
    while FARM_ACTIVE do
        task.wait(0.2)
        
        -- Procura o pumpkin mais próximo da posição atual
        local targetData = getClosestPumpkin()
        
        if targetData and targetData.Object and targetData.Part then
            -- 1. Leva o jogador até o pumpkin de forma suave (+5 no Y para evitar prender no chão)
            local targetPos = targetData.Part.Position + Vector3.new(0, 5, 0)
            smoothTweenTo(targetPos)
            
            -- 2. Ataca / Coleta até o pumpkin sumir do Workspace (ou limite de segurança de 4 segundos)
            local startTime = tick()
            while targetData.Object and targetData.Object.Parent and (tick() - startTime < 4) do
                attackPumpkin()
                task.wait(0.1)
            end
        else
            -- 3. Se não houver mais pumpkins na ilha atual, move para a ilha mais próxima suavemente
            local nextIsland = getNearestIsland()
            smoothTweenTo(nextIsland + Vector3.new(0, 15, 0))
            task.wait(1)
        end
    end
end)
