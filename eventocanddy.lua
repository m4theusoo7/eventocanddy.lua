-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local FARM_ACTIVE = true
local HIT_DELAY = 0.2 -- Velocidade dos ataques (intervalo entre os hits)

-- Função para encontrar a abóbora mais próxima que ainda existe
local function getNearestPumpkin()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local rootPart = character.HumanoidRootPart
    local nearest = nil
    local shortestDistance = math.huge
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Procura por objetos relacionados a abóboras
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

-- Função para garantir que o jogador está segurando/usando uma ferramenta (soco ou espada)
local function equipTool()
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Procura uma ferramenta no inventário e equipa
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local equippedTool = character:FindFirstChildOfClass("Tool")
    
    if not equippedTool and backpack then
        local tool = backpack:FindFirstChildOfClass("Tool")
        if tool then
            LocalPlayer.Character.Humanoid:EquipTool(tool)
        end
    end
end

-- Loop principal de farm em Loop
task.spawn(function()
    while FARM_ACTIVE do
        task.wait(0.1)
        
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local rootPart = character.HumanoidRootPart
            local targetPumpkin = getNearestPumpkin()
            
            if targetPumpkin then
                -- 1. Vai até a abóbora (posicionando um pouco acima ou perto)
                while targetPumpkin and targetPumpkin.Parent and FARM_ACTIVE do
                    -- Garante que equipou o soco/arma
                    equipTool()
                    
                    -- Move o personagem colado na abóbora
                    rootPart.CFrame = targetPumpkin.CFrame + Vector3.new(0, 2, 0)
                    
                    -- 2. Ativa o ataque (simula clique/soco)
                    local tool = character:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    else
                        -- Caso não tenha ferramenta equipada, tenta disparar o clique do mouse básico
                        if firesignal then
                            -- Alguns executores suportam simular input direto
                        end
                    end
                    
                    task.wait(HIT_DELAY)
                    
                    -- Se a abóbora foi destruída (saiu do workspace ou parent sumiu), sai do loop interno para buscar a próxima
                    if not targetPumpkin.Parent then
                        break
                    end
                end
            end
        end
    end
end)
