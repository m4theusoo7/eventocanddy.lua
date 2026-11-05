-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local FARM_ACTIVE = true
local HIT_DELAY = 0.15 -- Intervalo entre os cliques

-- Função para encontrar a abóbora mais próxima
local function getNearestPumpkin()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local rootPart = character.HumanoidRootPart
    local nearest = nil
    local shortestDistance = math.huge
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("pumpkin") or obj.Name:lower():find("abobora") then
            local part = obj:IsA("Model") and obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local distance = (rootPart.Position - part.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearest = part
                end
            end
        end
    end
    
    return nearest
end

-- Função para equipar a primeira ferramenta disponível (soco, estilo de luta ou espada)
local function equipTool()
    local character = LocalPlayer.Character
    if not character then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            local tool = backpack:FindFirstChildOfClass("Tool")
            if tool then
                character.Humanoid:EquipTool(tool)
            end
        end
    end
end

-- Função para simular o clique/soco de forma que o jogo registre
local function simulateClick()
    local character = LocalPlayer.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            -- Ativa a ferramenta se ela existir
            tool:Activate()
        end
    end
    
    -- Simula o clique do mouse na tela para garantir o golpe
    VirtualUser:Button1Down(Vector2.new(0, 0))
    task.wait(0.05)
    VirtualUser:Button1Up(Vector2.new(0, 0))
end

-- Loop principal
task.spawn(function()
    while FARM_ACTIVE do
        task.wait(0.1)
        
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local rootPart = character.HumanoidRootPart
            local targetPumpkin = getNearestPumpkin()
            
            if targetPumpkin then
                -- Fica focado na abóbora atual até que ela quebre
                while targetPumpkin and targetPumpkin.Parent and FARM_ACTIVE do
                    equipTool()
                    
                    -- Posiciona o personagem colado na abóbora
                    rootPart.CFrame = targetPumpkin.CFrame + Vector3.new(0, 2, 0)
                    
                    -- Executa o ataque simulado
                    simulateClick()
                    
                    task.wait(HIT_DELAY)
                    
                    -- Se a abóbora sumiu, sai do loop interno para ir para a próxima
                    if not targetPumpkin.Parent then
                        break
                    end
                end
            end
        end
    end
end)
