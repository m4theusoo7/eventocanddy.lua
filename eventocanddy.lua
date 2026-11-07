local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:FindFirstChildWhichIsA("BasePlate") -- Tenta achar a parte base (geralmente Torso ou Head)

-- --- CONFIGURAÇÕES ---
local Speed = 150 -- Velocidade de movimento
local JumpPower = 60 -- Força do pulo
local Range = 25 -- Distância para detectar itens/objetos
local Cooldown = 0.5 -- Tempo entre quebras (para não gastar muita energia)

-- Nome da sua habilidade de ataque (Ex: "Maestria", "Ataque Rápido", etc.)
-- Se não tiver certeza, tente "Maestria" primeiro
local AbilityName = "Maestria" 

-- Variáveis de Controle
local lastTouchTime = 0
local isJumping = false

-- Função para mover o personagem até um alvo (se a parte base existir)
function MoveToTarget(targetPart, targetCFrame)
    if not RootPart then return end -- Se não achar a parte base, sai da função
    
    local direction = (targetPart.Position - RootPart.Position).Unit * Speed
    Humanoid.WalkSpeed = math.min(Humanoid.WalkSpeed + 10, 350) -- Aumenta a velocidade
    
    if not isJumping then
        Humanoid.Jump = JumpPower
        isJumping = true
    end

    RootPart.CFrame = CFrame.new(RootPart.Position + direction) * targetCFrame
end

-- Função para quebrar objetos (Auto-Break)
function BreakObject(part, abilityName)
    -- Verifica se a habilidade existe e está ativa no personagem
    local abilityInstance = Character:FindFirstChild(abilityName) or Humanoid:FindFirstChild(abilityName)
    
    if abilityInstance and not isJumping then
        abilityInstance:Fire()
        lastTouchTime = tick()
        
        -- Ajuste de velocidade para o ataque (opcional, se quiser correr mais rápido ao atacar)
        Humanoid.WalkSpeed = 200
        
        return true
    end
    return false
end

-- Loop Principal do Farm
while true do
    wait(0.1) -- Verifica a cada 0.1 segundos
    
    local currentTime = tick()
    
    -- 1. Coleta de Itens (Tokens, Frutas, Orbes)
    local touchingParts = RootPart:GetTouchingParts()
    for _, part in ipairs(touchingParts) do
        if part.Parent ~= Character and part.Name:find("Item") or part.Name:find("Token") then
            -- Se estiver tocando em um item, pule para pegar
            MoveToTarget(part, CFrame.new(RootPart.Position + (part.Position - RootPart.Position).Unit * 2))
        end
    end

    -- 2. Quebra de Objetos (Caixas, Rochas, etc.)
    local nearestPart = nil
    local nearestDistance = math.huge
    
    for _, part in ipairs(RootPart:GetTouchingParts()) do
        if not part.Parent:FindFirstChild("Item") and not part.Name:find("Token") then
            -- Se não for um item comum, pode ser uma caixa ou rocha para quebrar
            local dist = (part.Position - RootPart.Position).Magnitude
            if dist < Range and dist < nearestDistance then
                nearestPart = part
                nearestDistance = dist
            end
        end
    end

    -- Se encontrar um objeto próximo, tenta quebrar
    if nearestPart and currentTime - lastTouchTime > Cooldown then
        MoveToTarget(nearestPart, CFrame.new(RootPart.Position + (nearestPart.Position - RootPart.Position).Unit * 2))
        
        -- Tenta usar a habilidade de ataque
        if BreakObject(nearestPart, AbilityName) then 
            -- Se o script da Maestria não funcionar automaticamente, você pode precisar ajustar o nome da Ability
            -- Exemplo para Ataque Rápido: BreakObject(nearestPart, "Ataque Rápido")
        end
    end

    -- 3. Ajuste de Velocidade Base (para não ficar muito lento)
    if Humanoid.WalkSpeed < 150 then
        Humanoid.WalkSpeed = math.min(Humanoid.WalkSpeed + 2, 150)
    end
    
    -- Pulo automático se estiver correndo rápido e perto do chão (opcional para farmar)
    if currentTime - lastTouchTime < 0.3 and not isJumping then
        Humanoid.Jump = JumpPower
        isJumping = true
    end

end
