local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local tweenSpeed = 250 -- Velocidade de voo (250 é seguro para o anti-cheat)
local isFarming = true

-- Função para encontrar e ordenar os Pumpkins do mais perto para o mais longe
local function getClosestPumpkins()
    local pumpkins = {}
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return pumpkins end
    local hrp = char.HumanoidRootPart

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Pumpkin" then
            -- Identifica a parte principal do Pumpkin para pegar a posição
            local targetPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj or nil)
            
            if targetPart then
                local dist = (hrp.Position - targetPart.Position).Magnitude
                table.insert(pumpkins, {model = obj, part = targetPart, distance = dist})
            end
        end
    end

    -- Ordena a tabela pela distância (menor para maior)
    table.sort(pumpkins, function(a, b) return a.distance < b.distance end)
    return pumpkins
end

-- Sistema de Noclip para atravessar paredes enquanto voa
local noclipConnection
local function enableNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

-- Função de Voo (Tween)
local function tweenTo(targetCFrame)
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

-- Função para atacar e usar skills
local function attackAndUseSkills()
    -- Clique normal (M1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)

    -- Uso de skills (Z, X, C, V)
    local skills = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
    for _, key in ipairs(skills) do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
        task.wait(0.1) -- Pequeno delay para o jogo registrar as skills
    end
end

-- Loop principal do Farm
local function startPumpkinFarm()
    enableNoclip()

    while isFarming do
        local pumpkins = getClosestPumpkins()

        if #pumpkins == 0 then
            -- Se não achar nenhum, aguarda 5 segundos antes de procurar de novo
            task.wait(5)
            continue
        end

        for _, targetData in ipairs(pumpkins) do
            if not isFarming then break end

            local targetModel = targetData.model
            local targetPart = targetData.part

            -- Fica em loop atacando ESSE pumpkin específico até ele sumir do mapa
            while targetModel and targetModel.Parent and isFarming do
                local char = player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then break end
                
                local hrp = char.HumanoidRootPart
                local distance = (hrp.Position - targetPart.Position).Magnitude

                if distance > 15 then
                    -- Se estiver longe, voa até ele (fica um pouco acima para não bugar no chão)
                    local tween = tweenTo(targetPart.CFrame * CFrame.new(0, 7, 0))
                    tween.Completed:Wait()
                else
                    -- Se estiver perto (menos de 15 studs), vira de frente e ataca
                    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPart.Position.X, hrp.Position.Y, targetPart.Position.Z))
                    attackAndUseSkills()
                    task.wait(0.2)
                end
            end
        end
        task.wait(1)
    end
    
    if noclipConnection then noclipConnection:Disconnect() end
end

-- Inicia o script
task.spawn(startPumpkinFarm)
