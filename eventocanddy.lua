local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootpart = character:FindFirstChild("HumanoidRootPart")

-- Configurações
local speed = 28 -- Velocidade de movimento (Ajuste se quiser mais rápido)
local pickupDistance = 3.5 -- Distância para pegar o item
local checkInterval = 0.15 -- Tempo entre verificações (quanto menor, mais preciso)

-- Função principal de loop
while true do
    wait(checkInterval)
    
    local targetItem = nil
    
    -- Procura por itens no chão
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Verifica se é um item pegável (tem PrimaryPartCFrame ou nome específico)
            local isPickupable = false
            
            -- Método 1: Verifica propriedade PrimaryPartCFrame (padrão de itens no Blox Fruits)
            if part.PrimaryPartCFrame then 
                isPickupable = true
            end
            
            -- Método 2: Verifica nomes comuns de itens/eventos (como Pumpkin, Item, etc.)
            if not isPickupable and (part.Name == "Item" or part.Name == "Pumpkin" or part.Name == "JackO_Lantern") then
                isPickupable = true
            end
            
            -- Se for um item pegável e estiver perto
            if isPickupable then
                local distance = rootpart.Position:Distance(part.Position)
                
                if distance <= pickupDistance then
                    targetItem = part
                elseif distance < 15 and distance > pickupDistance then
                    -- Se estiver dentro da área de busca, move-se para ele suavemente
                    local direction = (part.CFrame.p - rootpart.CFrame.p).Unit * speed
                    rootpart.CFrame = rootpart.CFrame + direction
                    
                    if distance <= pickupDistance then
                        targetItem = part
                    end
                end
            end
        end
    end
    
    -- Se encontrou o item, tenta pegar com segurança
    if targetItem and targetItem.PrimaryPartCFrame then
        tryCatch(targetItem:Pickup())
    elseif targetItem then
         -- Fallback para itens mais simples que não têm PrimaryPartCFrame direto
         local pickupFunc = targetItem.Parent:FindFirstChild("PrimaryPartCFrame") or function(p) return p:Pickup end
         if pickupFunc and type(pickupFunc) == "function" then 
             tryCatch(pickupFunc(targetItem))
         else
            -- Tenta pegar diretamente se for um objeto simples
            tryCatch(targetItem:Pickup())
         end
    end
end

-- Função auxiliar para evitar erros no console
local function tryCatch(func)
    local success, result = pcall(func)
    if not success then
        print("Tentativa de pegar falhou (provavelmente já pegou ou está longe): " .. tostring(result))
    end
end
