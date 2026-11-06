--[[
    PUMPKIN FARM PRO / BLOX FRUITS
    Versão aprimorada e otimizada
    Funcionalidades: detecção inteligente de abóboras, voo suave,
    equipar arma automaticamente, GUI de status, suporte a respawn
    e anti-colisão apenas durante o farm.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- ⚙️ CONFIGURAÇÕES
local Config = {
    ToggleKey      = Enum.KeyCode.F,
    IslandRadius   = 500,      -- raio para considerar mesma ilha
    FlySpeed       = 500,      -- velocidade do voo (studs/s)
    MinDistance    = 6,        -- distância mínima para começar a atacar
    FloatHeight    = 4,        -- altura acima da abóbora
    MaxAttackTime  = 8,        -- tempo máximo atacando uma abóbora (s)
    AttackInterval = 0.15,     -- intervalo entre ataques (s)
    ScanInterval   = 1.5,      -- intervalo entre varreduras de abóboras (s)
    AutoEquip      = true,     -- equipar arma da mochila automaticamente
    ShowGUI        = true,     -- mostrar interface na tela
}

-- 📦 ESTADO
local State = {
    Farming   = false,
    Thread    = nil,
    LastScan  = 0,
    Pumpkins  = {},
    GUI       = nil,
    SteppedConn = nil,
}

-- 🛠 FUNÇÕES AUXILIARES

local function getCharacter()
    return player.Character
end

local function getRoot()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getTool()
    local char = getCharacter()
    if not char then return nil end

    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool end

    if Config.AutoEquip then
        local hum = getHumanoid()
        local bpTool = player.Backpack:FindFirstChildOfClass("Tool")
        if bpTool and hum then
            hum:EquipTool(bpTool)
            task.wait(0.15) -- tempo para a equipar de fato
            return bpTool
        end
    end
    return nil
end

local function isPumpkin(obj)
    local name = obj.Name:lower()
    return name == "jack o' lantern"
        or name:find("pumpkin")
        or name:find("abobora")
end

local function scanPumpkins()
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isPumpkin(obj) then
            local part
            if obj:IsA("Model") then
                part = obj.PrimaryPart
                   or obj:FindFirstChild("HumanoidRootPart")
                   or obj:FindFirstChildWhichIsA("BasePart")
            elseif obj:IsA("BasePart") then
                part = obj
            end
            if part then
                table.insert(list, {
                    Model = obj,
                    Part  = part,
                    Pos   = part.Position,
                })
            end
        end
    end
    return list
end

local function getPumpkinsNear(rootPos, radius)
    local all = scanPumpkins()
    local near = {}
    for _, p in ipairs(all) do
        if (p.Pos - rootPos).Magnitude <= radius then
            table.insert(near, p)
        end
    end
    table.sort(near, function(a, b)
        return (a.Pos - rootPos).Magnitude < (b.Pos - rootPos).Magnitude
    end)
    return near
end

-- ✈️ VOO SUAVE ATÉ O ALVO
local function flyTo(targetPos)
    local root = getRoot()
    if not root then return false end

    local dist = (targetPos - root.Position).Magnitude
    if dist < Config.MinDistance then return true end

    local time = math.max(dist / Config.FlySpeed, 0.1)
    local goal = CFrame.lookAt(
        targetPos + Vector3.new(0, Config.FloatHeight, 0),
        targetPos
    )

    local tween = TweenService:Create(
        root,
        TweenInfo.new(time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { CFrame = goal }
    )

    root.Anchored = true
    local done = false
    local conn = tween.Completed:Connect(function() done = true end)
    tween:Play()

    while not done and root and root.Parent do
        task.wait(0.05)
    end

    if conn then conn:Disconnect() end
    if root and root.Parent then
        root.Anchored = false
    end
    return done
end

-- 🗡 ATACAR ABÓBORA
local function attackPumpkin(pumpkin)
    local startTime = os.clock()
    local targetPos = pumpkin.Part.Position

    while State.Farming
        and pumpkin.Model and pumpkin.Model.Parent
        and pumpkin.Part and pumpkin.Part.Parent do

        if os.clock() - startTime > Config.MaxAttackTime then break end

        local tool = getTool()
        if tool then
            pcall(function() tool:Activate() end)
        end

        local root = getRoot()
        if root then
            root.CFrame = CFrame.lookAt(
                targetPos + Vector3.new(0, Config.FloatHeight, 0),
                targetPos
            )
            root.AssemblyLinearVelocity = Vector3.zero
        end

        task.wait(Config.AttackInterval)
    end
end

-- 🔄 LOOP PRINCIPAL
local function farmLoop()
    while State.Farming do
        local root = getRoot()
        local hum = getHumanoid()

        if not root or not hum or hum.Health <= 0 then
            task.wait(0.5)
            continue
        end

        -- Verifica se já passou tempo suficiente para revarrer
        local now = os.clock()
        local pumpkins
        if now - State.LastScan >= Config.ScanInterval then
            pumpkins = getPumpkinsNear(root.Position, Config.IslandRadius)
            State.Pumpkins = pumpkins
            State.LastScan = now
        else
            pumpkins = State.Pumpkins
        end

        -- Se não achou nada nessa ilha, procura a próxima ilha mais próxima
        if #pumpkins == 0 then
            local all = scanPumpkins()
            if #all > 0 then
                table.sort(all, function(a, b)
                    return (a.Pos - root.Position).Magnitude < (b.Pos - root.Position).Magnitude
                end)
                local center = all[1].Pos
                local cluster = {}
                for _, p in ipairs(all) do
                    if (p.Pos - center).Magnitude <= Config.IslandRadius then
                        table.insert(cluster, p)
                    end
                end
                if #cluster > 0 then
                    pumpkins = cluster
                    State.Pumpkins = cluster
                end
            end
        end

        table.sort(pumpkins, function(a, b)
            return (a.Pos - root.Position).Magnitude < (b.Pos - root.Position).Magnitude
        end)

        for _, p in ipairs(pumpkins) do
            if not State.Farming then break end
            if p.Model and p.Model.Parent and p.Part and p.Part.Parent then
                local dist = (p.Pos - root.Position).Magnitude
                if dist > Config.MinDistance then
                    flyTo(p.Pos)
                end
                if not State.Farming then break end
                attackPumpkin(p)
            end
        end

        task.wait(0.3)
    end
    State.Thread = nil
end

-- 🖥 GUI DE STATUS
local function createGUI()
    if State.GUI then State.GUI:Destroy() end

    local targetGui = CoreGui
    local ok, err = pcall(function()
        return targetGui:FindFirstChildWhichIsA("ScreenGui") ~= nil
    end)
    if not ok then targetGui = player:WaitForChild("PlayerGui") end

    local gui = Instance.new("ScreenGui")
    gui.Name = "PumpkinFarmProGUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = targetGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 110)
    frame.Position = UDim2.new(0, 20, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 140, 0)
    stroke.Thickness = 2
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 26)
    title.Position = UDim2.new(0, 5, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = "PUMPKIN FARM PRO"
    title.TextColor3 = Color3.fromRGB(255, 140, 0)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -10, 0, 26)
    status.Position = UDim2.new(0, 5, 0, 36)
    status.BackgroundTransparency = 1
    status.Text = "Status: DESLIGADO"
    status.TextColor3 = Color3.fromRGB(255, 60, 60)
    status.TextScaled = true
    status.Font = Enum.Font.Gotham
    status.Name = "StatusLabel"
    status.Parent = frame

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, -10, 0, 20)
    hint.Position = UDim2.new(0, 5, 0, 66)
    hint.BackgroundTransparency = 1
    hint.Text = "Pressione [F] para alternar"
    hint.TextColor3 = Color3.fromRGB(180, 180, 180)
    hint.TextScaled = true
    hint.Font = Enum.Font.Gotham
    hint.Parent = frame

    State.GUI = gui
    return gui
end

local function updateGUI()
    if not State.GUI then return end
    local label = State.GUI:FindFirstChild("StatusLabel", true)
    if label then
        if State.Farming then
            label.Text = "Status: FARMANDO..."
            label.TextColor3 = Color3.fromRGB(60, 255, 60)
        else
            label.Text = "Status: DESLIGADO"
            label.TextColor3 = Color3.fromRGB(255, 60, 60)
        end
    end
end

-- ⌨ TOGGLE COM TECLA F
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.ToggleKey then
        State.Farming = not State.Farming
        updateGUI()
        print("[Pumpkin Farm] Estado:", State.Farming and "LIGADO" or "DESLIGADO")

        if State.Farming then
            if not State.Thread then
                State.Thread = task.spawn(farmLoop)
            end
        end
    end
end)

-- 🚫 ANTI-COLISÃO (apenas enquanto farmando)
State.SteppedConn = RunService.Stepped:Connect(function()
    if State.Farming then
        local char = getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- 🔁 SUPORTE A RESPAWN
player.CharacterAdded:Connect(function()
    task.wait(1)
    if State.Farming and not State.Thread then
        State.Thread = task.spawn(farmLoop)
    end
end)

-- 🚀 INICIALIZAÇÃO
if Config.ShowGUI then
    createGUI()
end

print("[Pumpkin Farm Pro] Carregado! Pressione F para começar.")
