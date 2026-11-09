local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local tweenSpeed = 300 -- Velocidade segura

-- Inicia o farm DESLIGADO
getgenv().FarmPumpkinAtivo = false

-- Lista de nomes dos inimigos que saem da abóbora (Adicione outros se precisar)
local monstrosHalloween = {"Ghost", "Wraith", "Skeleton", "Zombie", "Vampire"}

local function isMonstroEvento(nome)
    for _, monstro in ipairs(monstrosHalloween) do
        -- Verifica se o nome do NPC contém o nome da lista
        if string.find(nome, monstro) then 
            return true 
        end
    end
    return false
end

---------------------------------------------------------
-- SISTEMA DE INTERFACE FLUTUANTE (BOTÃO REDONDO)
---------------------------------------------------------
-- Limpa a UI antiga se você executar o script duas vezes no Delta
local uiName = "BotaoFarmPumpkin"
if CoreGui:FindFirstChild(uiName) then
    CoreGui[uiName]:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = uiName
screenGui.Parent = CoreGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 55, 0, 55)
toggleBtn.Position = UDim2.new(0.5, -27, 0.2, 0) -- Posição inicial (centro superior)
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Vermelho (Desligado)
toggleBtn.Text = "OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.FredokaOne
toggleBtn.TextSize = 20
toggleBtn.Parent = screenGui

-- Deixa o botão redondo
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = toggleBtn

-- Borda branca
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Parent = toggleBtn

-- Lógica para arrastar o botão (Touch/Mouse)
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = toggleBtn.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

toggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

---------------------------------------------------------
-- SISTEMA DE FÍSICA E FARM
---------------------------------------------------------
local noclipConnection
local function setupPhysics()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
            
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

-- Voo suave
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

-- Busca APENAS os inimigos do evento
local function getInimigoProximo()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    
    local closestEnemy = nil
    local shortestDistance = 80

    if Workspace:FindFirstChild("Enemies") then
        for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
            if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 and enemy:FindFirstChild("HumanoidRootPart") then
                -- O SEGREDO ESTÁ AQUI: Só foca se for monstro do evento
                if isMonstroEvento(enemy.Name) then
                    local dist = (hrp.Position - enemy.HumanoidRootPart.Position).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestEnemy = enemy
                    end
                end
            end
        end
    end
    return closestEnemy
end

-- Busca a abóbora
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

-- Simula Ataques
local function usarAtaques()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    
    local skills = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
    for _, key in ipairs(skills) do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

-- Lógica Principal
local function iniciarFarm()
    setupPhysics()

    while getgenv().FarmPumpkinAtivo do
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            task.wait(1)
            continue
        end
        local hrp = char.HumanoidRootPart

        -- PRIORIDADE 1: Inimigo do evento vivo perto?
        local inimigo = getInimigoProximo()
        if inimigo then
            local enemyHrp = inimigo.HumanoidRootPart
            local dist = (hrp.Position - enemyHrp.Position).Magnitude
            
            if dist > 8 then
                local tween = tweenPara(enemyHrp.CFrame * CFrame.new(0, 6, 0)) 
                tween.Completed:Wait()
            else
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(enemyHrp.Position.X, hrp.Position.Y, enemyHrp.Position.Z))
                usarAtaques()
            end
            task.wait(0.1)
            continue
        end

        -- PRIORIDADE 2: Abóbora
        local pumpkin = getPumpkinProxima()
        if pumpkin then
            local targetPart = pumpkin.part
            local dist = (hrp.Position - targetPart.Position).Magnitude
            
            if dist > 15 then
                local tween = tweenPara(targetPart.CFrame * CFrame.new(0, 7, 0))
                tween.Completed:Wait()
            else
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPart.Position.X, hrp.Position.Y, targetPart.Position.Z))
                usarAtaques()
            end
            task.wait(0.1)
            continue
        end

        task.wait(1)
    end
    
    removePhysics()
end

---------------------------------------------------------
-- ATIVAÇÃO DO BOTÃO
---------------------------------------------------------
toggleBtn.MouseButton1Click:Connect(function()
    getgenv().FarmPumpkinAtivo = not getgenv().FarmPumpkinAtivo
    
    if getgenv().FarmPumpkinAtivo then
        -- LIGA
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        toggleBtn.Text = "ON"
        task.spawn(iniciarFarm)
    else
        -- DESLIGA
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        toggleBtn.Text = "OFF"
        removePhysics() -- Devolve a gravidade imediatamente
    end
end)
