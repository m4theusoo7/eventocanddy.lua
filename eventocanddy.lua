-- Serviços necessários
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local TARGET_NAME = "Pumpkin" -- Nome comum para abóboras em eventos
local FARM_ACTIVE = true

-- Função para encontrar e quebrar as abóboras na Cidade Central
local function getNearestPumpkin()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local rootPart = character.HumanoidRootPart
    local nearest = nil
    local shortestDistance = math.huge
    
    -- Varre o Workspace procurando objetos que correspondam à abóbora
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("pumpkin") or obj.Name:lower():find("abobora") then
            local part = obj:FindFirstChildWhichIsA("BasePart")
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

-- Loop principal de movimentação e quebra
task.spawn(function()
    while FARM_ACTIVE do
        task.wait(0.1)
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local targetPumpkin = getNearestPumpkin()
            
            if targetPumpkin then
                -- Move o personagem até a abóbora
                character.HumanoidRootPart.CFrame = targetPumpkin.CFrame + Vector3.new(0, 3, 0)
                
                -- Simula o ataque/clique para quebrar (dependendo de como o jogo registra o hit)
                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                end
            end
        end
    end
end)
