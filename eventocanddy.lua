-- Serviços necessários
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local FARM_ACTIVE = true
local HIT_DELAY = 0.1 -- Intervalo rápido entre os cliques

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

-- Função para garantir que o soco/arma está equipado
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

-- Função de Auto Click usando o VirtualInputManager (simula o clique físico na tela)
local function clickMouse()
    local vim = VirtualInputManager
    local viewportSize = Workspace.CurrentCamera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2
    
    -- Simula pressionar e soltar o botão esquerdo no centro da tela (onde o personagem ataca)
    vim:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.02)
    vim:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
end

-- Loop principal de farm e quebra
task.spawn(function()
    while FARM_ACTIVE do
        task.wait(0.05)
        
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local rootPart = character.HumanoidRootPart
            local targetPumpkin = getNearestPumpkin()
            
            if targetPumpkin then
                -- Fica focado na abóbora até ela sumir do jogo
                while targetPumpkin and targetPumpkin.Parent and FARM_ACTIVE do
                    equipTool()
                    
                    -- Posiciona o personagem colado na abóbora
                    rootPart.CFrame = targetPumpkin.CFrame + Vector3.new(0, 3, 0)
                    
                    -- Dispara o Auto Click
                    clickMouse()
                    
                    task.wait(HIT_DELAY)
                    
                    -- Se a abóbora quebrou/desapareceu, sai do loop para ir na próxima
                    if not targetPumpkin.Parent then
                        break
                    end
                end
            end
        end
    end
end)
