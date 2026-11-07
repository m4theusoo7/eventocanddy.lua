local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Torso = Character:WaitForChild("Torso")
local RootPart = Torso:FindFirstChildWhichIsA("BasePlate") -- Ajuste se for outra parte base

-- Configurações
local Speed = 150 -- Velocidade de movimento (quanto maior, mais rápido)
local JumpPower = 60 -- Força do pulo
local Range = 25 -- Distância para detectar itens/objetos
local Cooldown = 0.5 -- Tempo entre quebras (para não gastar muita energia)

-- Variáveis de Controle
local lastTouchTime = 0
local isJumping = false

-- Função para mover o personagem
function MoveToTarget(targetPart, targetCFrame)
    local direction = (targetPart.Position - Torso.Position).Unit * Speed
    Humanoid.WalkSpeed = math.min(Humanoid.WalkSpeed + 10, 350) -- Aumenta a velocidade
    
    if not isJumping then
        Humanoid.Jump = JumpPower
        isJumping = true
    end

    Torso.CFrame = CFrame.new(Torso.Position + direction) * targetCFrame
end

-- Função para quebrar objetos (Auto-Break)
function BreakObject(part, abilityName)
    -- Verifica se a habilidade existe e está ativa
    local abilityInstance = Player.Character:FindFirstChild(abilityName) or Humanoid:FindFirstChild(abilityName)
    
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
    local touchingParts = Torso:GetTouchingParts()
    for _, part in ipairs(touchingParts) do
        if part.Parent ~= Character and part.Name:find("Item") or part.Name:find("Token") then
            -- Se estiver tocando em um item, pule para pegar (ou use a função de coletar se tiver script específico)
            MoveToTarget(part, CFrame.new(Torso.Position + (part.Position - Torso.Position).Unit * 2))
        end
    end

    -- 2. Quebra de Objetos (Caixas, Rochas, etc.)
    local nearestPart = nil
    local nearestDistance = math.huge
    
    for _, part in ipairs(Torso:GetTouchingParts()) do
        if not part.Parent:FindFirstChild("Item") and not part.Name:find("Token") then
            -- Se não for um item comum, pode ser uma caixa ou rocha para quebrar
            local dist = (part.Position - Torso.Position).Magnitude
            if dist < Range and dist < nearestDistance then
                nearestPart = part
                nearestDistance = dist
            end
        end
    end

    -- Se encontrar um objeto próximo, tenta quebrar
    if nearestPart and currentTime - lastTouchTime > Cooldown then
        MoveToTarget(nearestPart, CFrame.new(Torso.Position + (nearestPart.Position - Torso.Position).Unit * 2))
        
        -- Tenta usar a habilidade de ataque (ex: "Maestria" ou "Ataque Rápido")
        if BreakObject(nearestPart, "Maestria") then 
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
