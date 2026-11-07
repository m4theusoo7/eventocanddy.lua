local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootpart = character:FindFirstChild("HumanoidRootPart")
local humanoid = character:FindFirstChild("Humanoid")

-- Configurações
local speed = 16 -- Velocidade de movimento (quanto maior, mais rápido)
local attackDistance = 8 -- Distância para atacar/interagir
local pumpkinName = "Pumpkin" -- Nome da abóbora (pode ser "Halloween_Pumpkin", etc.)

-- Função para encontrar a abóbora mais próxima
local function FindNearestPumpkin()
    local target = workspace:FindFirstChild(pumpkinName)
    
    if not target then
        for _, child in ipairs(workspace:GetDescendants()) do
            -- Procura por qualquer coisa que tenha "Pumpkin" no nome
            if string.find(child.Name, pumpkinName) and child:IsA("Part") or child:IsA("Model") then
                return child
            end
        end
    end
    
    return target
end

-- Loop principal do script
while true do
    local target = FindNearestPumpkin()
    
    if target and rootpart and humanoid then
        -- Verifica distância
        local distance = (rootpart.Position - target.Position).Magnitude
        
        if distance <= attackDistance then
            print("🎃 Abóbora encontrada! Atacando...")
            
            -- Lógica de ataque: 
            -- Se for apenas colisão, o personagem já vai bater.
            -- Se precisar usar uma habilidade específica (ex: Rapid Punch), descomente abaixo:
            -- humanoid:ChangeState(2) -- Muda para estado de ataque
            
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
