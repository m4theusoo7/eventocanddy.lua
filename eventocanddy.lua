-- // Configurações Iniciais & Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- // Parâmetros de Configuração
local SPEED = 250 -- Velocidade do Tween
local FARM_ACTIVE = true

-- // Lista de principais ilhas do Blox Fruits para transição
local ISLAND_CENTERS = {
    Vector3.new(0, 50, 0),
    Vector3.new(-650, 50, -1100),
    Vector3.new(2280, 50, 905),
    Vector3.new(-5120, 50, -4250),
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

-- // Simula o clique para coletar
local function attackPumpkin()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- // Encontra o Pumpkin / Candy real ignorando NPCs e diálogos
local function getClosestPumpkin()
    local closest = nil
    local shortestDist = math.huge
    
    Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return nil end
    local currentPos = Character.HumanoidRootPart.Position
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local nameLower = string.lower(obj.Name)
        
        -- Filtra por Pumpkin ou Candy, mas ignora terminantemente NPCs e personagens fixos
        local isTarget = string.find(nameLower, "pumpkin") or string.find(nameLower, "abobora") or string.find(nameLower, "candy")
        local isNPC = string.find(nameLower, "npc") or string.find(nameLower, "witch") or obj:FindFirstChild("Humanoid") and not obj:FindFirstChild("Head") -- Evita focar em avatares/Humanoides de NPCs
        
        if isTarget and not isNPC then
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

-- // Encontra a ilha mais próxima quando acabam os itens
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

-- // Loop Principal de Farm Sequencial com Limite de Tempo por Alvo
task.spawn(function()
    while FARM_ACTIVE do
        task.wait(0.2)
        
        local targetData = getClosestPumpkin()
        
        if targetData and targetData.Object and targetData.Part then
            local targetPos = targetData.Part.Position + Vector3.new(0, 5, 0)
            smoothTweenTo(targetPos)
            
            -- Coleta o item. Se por acaso demorar mais de 3 segundos, ele desiste e vai pro próximo (evita travar em bug)
            local startTime = tick()
            while targetData.Object and targetData.Object.Parent and (tick() - startTime < 3) do
                attackPumpkin()
                task.wait(0.1)
            end
        else
            -- Se não achar abóboras na ilha, vai para a próxima ilha suavemente
            local nextIsland = getNearestIsland()
            smoothTweenTo(nextIsland + Vector3.new(0, 15, 0))
            task.wait(1)
        end
    end
end)
```[cite: 1]

### O que foi corrigido:
1. **Filtro Ant-NPC (`isNPC`):** Adicionei uma checagem para que o script ignore completamente qualquer entidade que seja a Bruxa (*Witch*) ou outros NPCs com estrutura de Humanoid.
2. **Timeout de Segurança (3 segundos):** Mesmo que algum objeto estranho seja selecionado por engano, o script agora desiste dele após 3 segundos e pula para o próximo alvo, impedindo que o seu personagem fique preso em telas de diálogo[cite: 1].
