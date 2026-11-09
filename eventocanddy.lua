local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local tweenSpeed = 300 -- Velocidade segura

-- Variável global para você poder parar o script depois se quiser
getgenv().FarmPumpkinAtivo = true

-- Sistema que anula a gravidade e desativa colisão (Corrige o bug de teleporte)
local noclipConnection
local function setupPhysics()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            
            -- Desativa a colisão de tudo (atravessar paredes)
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
            
            -- Cria a gravidade zero para o anti-cheat não te puxar de volta
            local bv = hrp:FindFirstChild("AntiBorracha")
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "AntiBorracha"
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Velocity = Vector3.new(0, 0, 0)
                bv.Parent = hrp
            end
            
            -- Zera a velocidade física do personagem para evitar pulos estranhos
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function removePhysics()
    if noclipConnection then noclipConnection:Disconnect() end
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local bv = char.HumanoidRootPart:FindFirstChild("AntiBorracha")
        if bv then bv:Destroy() end
    end
end

-- Voo suave com Tween
local function tweenPara(targetCFrame)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local timeToTravel = distance / tweenSpeed
    
    local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    return tween
end

-- Busca o inimigo mais próximo que surgiu da abóbora
local function getInimigoProximo()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    
    local closestEnemy = nil
    local shortestDistance = 80 -- Raio de busca (só foca inimigos que surgiram perto)

    if Workspace:FindFirstChild("Enemies") then
        for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
            if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 and enemy:FindFirstChild("HumanoidRootPart") then
                local dist = (hrp.Position - enemy.HumanoidRootPart.Position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestEnemy = enemy
                end
            end
        end
    end
    return closestEnemy
end

-- Busca a abóbora mais próxima
local function getPumpkinProxima()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    
    local closestPumpkin = nil
    local shortestDistance = math.huge

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Pumpkin" then
            local targetPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj or nil)
            if targetPart then
                local dist = (hrp.Position - targetPart.Position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestPumpkin = {model = obj, part = targetPart}
                end
            end
        end
    end
    
    return closestPumpkin
end

-- Simula os ataques (Cliques e Skills)
local function usarAtaques()
    -- Clica o Mouse (M1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    
    -- Teclas Z, X, C, V
    local skills = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
    for _, key in ipairs(skills) do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

-- Lógica central do Farm
local function iniciarFarm()
    setupPhysics()

    while getgenv().FarmPumpkinAtivo do
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            task.wait(1)
            continue
        end
        local hrp = char.HumanoidRootPart

        -- PRIORIDADE 1: Tem inimigo vivo perto? Mata primeiro.
        local inimigo = getInimigoProximo()
        if inimigo then
            local enemyHrp = inimigo.HumanoidRootPart
            local dist = (hrp.Position - enemyHrp.Position).Magnitude
            
            if dist > 8 then
                -- Fica um pouco acima do NPC para tomar menos dano
                local tween = tweenPara(enemyHrp.CFrame * CFrame.new(0, 6, 0)) 
                tween.Completed:Wait()
            else
                -- Vira de frente para o NPC e ataca (importante para as skills acertarem)
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(enemyHrp.Position.X, hrp.Position.Y, enemyHrp.Position.Z))
                usarAtaques()
            end
            task.wait(0.1) -- Delay seguro para não travar o Delta
            continue
        end

        -- PRIORIDADE 2: Se não tem inimigo, vai para o Pumpkin
        local pumpkin = getPumpkinProxima()
        if pumpkin then
            local targetPart = pumpkin.part
            local dist = (hrp.Position - targetPart.Position).Magnitude
            
            if dist > 15 then
                local tween = tweenPara(targetPart.CFrame * CFrame.new(0, 7, 0))
                tween.Completed:Wait()
            else
                -- Vira para o Pumpkin e ataca
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPart.Position.X, hrp.Position.Y, targetPart.Position.Z))
                usarAtaques()
            end
            task.wait(0.1)
            continue
        end

        -- Se não achar nada, espera um pouco para procurar novamente
        task.wait(1)
    end
    
    removePhysics()
end

-- Executa o farm
task.spawn(iniciarFarm)
