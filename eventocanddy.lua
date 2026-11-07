-- Garante que o jogo carregou
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game.Players
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local TweenService = game:GetService("TweenService")

-- Configurações do Blox Fruits
local ItemName = "Pumpkin" -- Nome do item ou inimigo (ex: abóbora, boss, etc.)
local Speed = 350          -- Velocidade do voo/teleporte (ajuste se achar muito rápido ou lento)
local AttackDelay = 0.4    -- Delay entre os ataques

-- Coordenadas das Ilhas Principais do Blox Fruits (Exemplos do Sea 1 / Sea 2 / Sea 3)
-- Dica: Você pode atualizar estas tabelas com as coordenadas exatas da ilha que você está farmando
local Islands = {
    [1] = Vector3.new(246, 15, 58),       -- Exemplo: Marine Fortress / Starter
    [2] = Vector3.new(-6500, 100, -4500), -- Exemplo: Ilha do Gelo / Outra ilha
    [3] = Vector3.new(1000, 20, 1500),    -- Exemplo genérico
}

local CurrentIslandIndex = 1

-- Função para obter a posição correta do alvo no jogo
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

-- Teleporte Suave / Voo (Tween) seguro para o Blox Fruits (atravessa o mar sem cair)
local function TweenTo(targetPos)
    if not targetPos then return end
    
    Character = Player.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = Character.HumanoidRootPart

    local distance = (rootPart.Position - targetPos).Magnitude
    local timeTaken = distance / Speed

    local tweenInfo = TweenInfo.new(
        timeTaken,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    -- Desativa o NoClip básico durante o voo para não bater em paredes
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
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
        -- Cancela se o personagem morrer
        if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
            tween:Cancel()
            break
        end
    end

    -- Restaura a colisão
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

-- Função de Ataque compatível com Estilos de Luta / Espadas no Blox Fruits
local function Attack()
    -- Simula o clique do mouse / ataque da ferramenta ativa no Blox Fruits
    pcall(function()
        local combatRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") 
        if combatRemote and combatRemote:FindFirstChild("Validator") then
            -- Alguns executores usam VirtualUser para simular cliques perfeitos
        end
        
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

-- Função para procurar o item/objeto no Workspace do Blox Fruits
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

-- Loop principal de Auto-Farm / Coleta
while true do
    Character = Player.Character or Player.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    local item = FindItem()

    if not item then
        print("Item não encontrado. A viajar para a ilha " .. CurrentIslandIndex)
        local targetIsland = Islands[CurrentIslandIndex]
        
        TweenTo(targetIsland)
        
        CurrentIslandIndex = (CurrentIslandIndex % #Islands) + 1
        task.wait(3)
    else
        print("Item encontrado no Blox Fruits! A ir ter com ele...")
        local itemPos = GetTargetPosition(item)
        
        if itemPos then
            TweenTo(itemPos)
            task.wait(0.5)

            -- Fica em cima do item e ataca/coleta até ele sumir
            while item and item.Parent ~= nil do
                local currentPos = GetTargetPosition(item)
                if currentPos then
                    HumanoidRootPart.CFrame = CFrame.new(currentPos + Vector3.new(0, 5, 0)) -- Fica flutuando em cima
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
