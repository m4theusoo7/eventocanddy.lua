local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configurações
local ItemName = "Pumpkin" -- Nome exato da abóbora (verifique no jogo)
local InteractionKey = Enum.KeyCode.E -- Tecla para coletar (E ou Z)
local WalkDistance = 10 -- Distância máxima para se mover até o item

-- Função principal de verificação
local function checkForItem()
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoidRootPart then return end

    -- Tenta encontrar o item no workspace ou em partes do personagem (caso seja um acessório)
    local targetItem = workspace:FindFirstChild(ItemName)
    
    if targetItem and targetItem.Parent ~= nil then
        local distance = (humanoidRootPart.Position - targetItem.Position).Magnitude
        
        -- Se estiver perto o suficiente, interage
        if distance <= 12 then
            print("Encontrou a abóbora! Pressionando " .. InteractionKey.Name)
            
            -- Simula o clique da tecla de interação
            UserInputService.InputBegan:Fire(InteractionKey)
            
            -- Opcional: Pula para não ficar parado (ajuste se necessário)
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                local humanoid = player.Character.Humanoid
                if humanoid.Health > 0 then
                    humanoid.Jump()
                end
            end
        else
            -- Se estiver longe, move o personagem em direção ao item
            print("Movendo para a abóbora...")
            
            local direction = (targetItem.Position - humanoidRootPart.Position).Unit * WalkDistance
            humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position + direction)
        end
    else
        -- Se o item não estiver no workspace, verifica se está em cima do personagem (caso seja um acessório)
        local characterItem = character:FindFirstChild(ItemName)
        if characterItem then
            print("Encontrou a abóbora no personagem! Pressionando " .. InteractionKey.Name)
            UserInputService.InputBegan:Fire(InteractionKey)
        end
    end
end

-- Loop de verificação (roda a cada frame)
RunService.Heartbeat:Connect(checkForItem)

print("Script de Farm Halloween ativado!")
