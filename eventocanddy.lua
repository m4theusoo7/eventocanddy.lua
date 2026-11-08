local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootpart = character:FindFirstChild("HumanoidRootPart")
local humanoid = character:FindFirstChild("Humanoid")

-- Configurações
local speed = 15 -- Velocidade de movimento (ajuste se for muito rápido)
local attackRange = 7 -- Distância para atacar/interagir
local pumpkinName = "Pumpkin" -- Nome padrão, mas o script procura por qualquer coisa com esse nome

print("🎃 Script de Abóbora Iniciado...")

-- Função para encontrar a abóbora mais próxima (busca recursiva)
local function FindNearestTarget()
    local targets = {}
    
    -- Procura em todo o workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if string.find(obj.Name, pumpkinName) and obj:IsA("Part") then
            table.insert(targets, obj)
        end
    end
    
    -- Se não achar nada com "Pumpkin", tenta encontrar objetos grandes (caso seja um modelo)
    if #targets == 0 then
        for _, obj in ipairs(workspace:GetDescendants()) do
             if string.find(obj.Name, pumpkinName) and obj:IsA("Model") or obj:IsA("Part") then
                table.insert(targets, obj)
            end
        end
    end
    
    -- Ordena por distância e retorna a mais próxima
    if #targets > 0 then
        local nearest = targets[1]
        for _, target in ipairs(targets) do
            if (rootpart.Position - target.Position).Magnitude < (rootpart.Position - nearest.Position).Magnitude then
                nearest = target
            end
        end
        return nearest
    else
        return nil
    end
end

-- Loop principal do script
while true do
    local target = FindNearestTarget()
    
    if target and rootpart and humanoid then
        -- Verifica distância
        local distance = (rootpart.Position - target.Position).Magnitude
        
        if distance <= attackRange then
            print("🎃 Abóbora encontrada! Atacando...")
            
            -- Move o personagem até a posição exata da abóbora
            rootpart.CFrame = CFrame.new(target.Position, target.Position + Vector3.new(0, 1.5, 0))
            
            -- Pequeno delay para garantir que bateu antes de procurar outra
            wait(2) 
        else
            -- Se estiver longe, move em direção à abóbora
            local direction = (target.Position - rootpart.Position).Unit
            rootpart:MoveTo(rootpart.Position + direction * speed)
            
            -- Mantém o personagem olhando para a abóbora
            humanoid.HumanoidRootPart.CFrame = CFrame.new(rootpart.Position, target.Position)
        end
        
    else
        print("🔍 Procurando abóboras...")
        wait(5) -- Espera 5 segundos se não encontrar nenhuma
    end
end
