local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootpart = character:FindFirstChild("HumanoidRootPart")

-- Configurações
local speed = 25 -- Velocidade de movimento (quanto maior, mais rápido)
local pickupDistance = 3.5 -- Distância para pegar o item (em studs)
local checkInterval = 0.1 -- Tempo entre verificações (quanto menor, mais preciso)

-- Função para encontrar itens no chão
while true do
    wait(checkInterval)
    
    local targetItem = nil
    
    -- Procura por partes com PrimaryPartCFrame (padrão de itens) ou nomes comuns de itens/eventos
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Verifica se é um item genérico ou específico (como a abóboga)
            local isItem = part.PrimaryPartCFrame or 
                           (part.Name == "Item" or part.Name == "Pumpkin" or part.Name == "JackO_Lantern" or part.Name:find("Item"))
            
            if isItem then
                -- Verifica se o item está perto do jogador
                local distance = rootpart.Position:Distance(part.Position)
                
                if distance <= pickupDistance then
                    targetItem = part
                elseif distance < 15 and distance > pickupDistance then
                    -- Se estiver dentro da área de busca, move-se para ele
                    local direction = (part.CFrame.p - rootpart.CFrame.p).Unit * speed
                    rootpart.CFrame = rootpart.CFrame + direction
                    
                    if distance <= pickupDistance then
                        targetItem = part
                    end
                end
            end
        end
    end
    
    -- Se encontrou o item, tenta pegar
    if targetItem and targetItem.PrimaryPartCFrame then
        targetItem:Pickup()
    elseif targetItem and not targetItem.PrimaryPartCFrame then
         -- Fallback para itens mais simples
         local pickupFunc = targetItem.Parent:FindFirstChild("PrimaryPartCFrame") or function(p) return p:Pickup end
         if pickupFunc then pickupFunc(targetItem) end
    end
end
