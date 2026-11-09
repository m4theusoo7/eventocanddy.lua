local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local tweenSpeed = 300 -- Velocidade de voo segura para o anti-cheat

-- Controle do script e nome do alvo
getgenv().FarmBossAtivo = true
local nomeDoBoss = "Hellfire Gas" -- Você pode mudar isso para farmar qualquer outro Boss depois

-- Sistema de Física (Anti-Borracha e Noclip para não travar em paredes)
local noclipConnection
local function setupPhysics()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            
            -- Desativa colisão
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
            
            -- Mantém o personagem flutuando estável
            local bv = hrp:FindFirstChild("AntiBorracha")
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "AntiBorracha"
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Velocity = Vector3.new(0, 0, 0)
                bv.Parent = hrp
            end
            
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

-- Voo suave pelo mapa
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

-- Busca o Boss na pasta de Inimigos
local function getBoss()
    if not Workspace:FindFirstChild("Enemies") then return nil end
    
    for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
        -- Transforma os dois nomes em minúsculas para não ter erro de letra maiúscula
        if string.find(string.lower(enemy.Name), string.lower(nomeDoBoss)) then
            if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 and enemy:FindFirstChild("HumanoidRootPart") then
                return enemy
            end
        end
    end
    return nil
end

-- Usa Cliques e Skills (Z, X, C, V)
local function usarAtaques()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    
    local skills = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
    for _, key in ipairs(skills) do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

-- Loop de Farm do Boss
local function iniciarFarmBoss()
    setupPhysics()

    while getgenv().FarmBossAtivo do
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            task.wait(1)
            continue
        end
        local hrp = char.HumanoidRootPart

        local boss = getBoss()
        
        if boss then
            local bossHrp = boss.HumanoidRootPart
            local dist = (hrp.Position - bossHrp.Position).Magnitude
            
            if dist > 15 then
                -- Vai até o boss ficando 10 studs acima (evita tomar alguns danos de chão)
                local tween = tweenPara(bossHrp.CFrame * CFrame.new(0, 10, 0)) 
                tween.Completed:Wait()
            else
                -- Trava a mira nele e ataca
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(bossHrp.Position.X, hrp.Position.Y, bossHrp.Position.Z))
                usarAtaques()
            end
        else
            -- Se o boss não estiver spawnado, o script só aguarda silenciosamente
            -- Você pode ficar fazendo outras coisas ou farmando itens enquanto ele espera
        end
        
        task.wait(0.1)
    end
    
    removePhysics()
end

-- Inicia o farm
task.spawn(iniciarFarmBoss)
