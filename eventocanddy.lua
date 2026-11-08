-- // Configurações Iniciais & Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- // Parâmetros de Configuração
local SPEED = 250 -- Velocidade em studs/s (estável e segura)
local FARM_ACTIVE = true

-- // Função para desativar colisões e evitar travar no cenário
local function bypassCollisions()
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

-- // Função de Tween para movimentação suave até o alvo
local function tweenTo(targetPosition)
    local distance = (HumanoidRootPart.Position - targetPosition).Magnitude
    local timeToTravel = distance / SPEED
    
    local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = CFrame.new(targetPosition + Vector3.new(0, 5, 0))})
    
    bypassCollisions()
    tween:Play()
    tween.Completed:Wait()
end

-- // Função para simular o ataque/clique na abóbora
local function simulateClick()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- // Varredura e Loop de Farm
task.spawn(function()
    while FARM_ACTIVE do
        task.wait(0.5)
        
        -- Garante referência atualizada do personagem
        Character = LocalPlayer.Character
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            HumanoidRootPart = Character.HumanoidRootPart
            
            local foundTarget = false
            
            -- Varre o Workspace em busca de abóboras ou itens do evento
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if not FARM_ACTIVE then break end
                
                -- Identifica o objeto pelo nome (Pumpkin, Abóbora, Candy ou similares)
                local nameLower = string.lower(obj.Name)
                if string.find(nameLower, "pumpkin") or string.find(nameLower, "abobora") or string.find(nameLower, "candy") then
                    local targetPart = nil
                    
                    if obj:IsA("Model") and obj.PrimaryPart then
                        targetPart = obj.PrimaryPart
                    elseif obj:IsA("BasePart") then
                        targetPart = obj
                    elseif obj:FindFirstChild("HumanoidRootPart") then
                        targetPart = obj.HumanoidRootPart
                    elseif obj:FindFirstChildWhichIsA("BasePart") then
                        targetPart = obj:FindFirstChildWhichIsA("BasePart")
                    end
                    
                    if targetPart then
                        foundTarget = true
                        
                        -- Move até o alvo
                        tweenTo(targetPart.Position)
                        
                        -- Fica batendo/coletando até o objeto sumir ou ser coletado
                        local startTime = tick()
                        while obj and obj.Parent and (tick() - startTime < 3) do
                            simulateClick()
                            task.wait(0.2)
                        end
                    end
                end
            end
            
            -- Se não achar nada no Workspace, aguarda um instante antes de nova varredura
            if not foundTarget then
                task.wait(1)
            end
        end
    end
end)
