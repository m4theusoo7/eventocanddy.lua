local Players = game.Players
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
local Delta = require(game.ReplicatedStorage.Delta) -- Ajuste o caminho se necessário

-- Configurações
local ItemName = "Pumpkin" -- Nome do item (baseado na imagem, pode ser "Model" ou "Enemy")
local Speed = 20           -- Velocidade de movimento
local AttackDelay = 0.5    -- Tempo entre ataques
local IslandSwitchCooldown = 10 -- Tempo para trocar de ilha se não achar nada

-- Tabela de Coordenadas das Ilhas (Exemplos comuns)
local Islands = {
    [1] = Vector3.new(246, -79, 58),   -- Marine Base (Geralmente onde começa)
    [2] = Vector3.new(-100, -100, 100),-- Sea Beast Island (Exemplo genérico)
    [3] = Vector3.new(400, 0, 50),     -- Ilha do Dragão (Exemplo genérico)
}

local CurrentIslandIndex = 1

-- Função para Teleporte Suave
function Delta.MoveTo(target, speed)
    if not target then return end
    
    local rootPart = HumanoidRootPart or Character:FindFirstChild("HumanoidRootPart")
    
    -- Cria uma cópia do alvo para não afetar o original se for um modelo complexo
    local TargetClone = Instance.new("Model")
    TargetClone.Name = "TeleportTarget"
    TargetClone.Parent = workspace
    
    local Part = Instance.new("Part")
    Part.Size = Vector3.new(1, 1, 1)
    Part.Anchored = true
    Part.CanCollide = false
    Part.Transparency = 0.5
    Part.Color = Color3.fromRGB(255, 255, 255) -- Cor branca para visualização (opcional)
    
    local Handle = Instance.new("BodyVelocity")
    Handle.Velocity = Vector3.zero
    
    Part.Parent = TargetClone
    Handle.Parent = Part
    
    -- Posiciona o alvo perto do jogador inicialmente se estiver longe
    if not rootPart:FindFirstChildWhichIsA("Model", ItemName) then
        local pos = target.Position + (rootPart.Position - target.Position).Unit * 5
        Part.Position = pos
    else
        Part.Position = target.Position
    end
    
    -- Configura a velocidade para ir até o alvo
    Handle.Velocity = (target.Position - rootPart.Position) * speed
    
    task.wait(1.5) -- Tempo de voo suave
    
    -- Limpa o clone após chegar
    TargetClone:Destroy()
end

-- Função para Atacar
function Delta.Attack(target)
    if not target then return end
    
    local Weapon = Character:FindFirstChild("RightHand") or Character:FindFirstChild("LeftHand")
    
    if not Weapon then
        -- Se não tiver arma, usa o corpo (ataque básico)
        local BodyThrust = Instance.new("BodyThrust")
        BodyThrust.Name = "AttackForce"
        BodyThrust.Parent = HumanoidRootPart
        
        local AttackVector = (target.Position - HumanoidRootPart.Position).Unit * 5
        BodyThrust.Velocity = AttackVector
        
        task.wait(0.2) -- Tempo de ataque
        BodyThrust:Destroy()
    else
        -- Se tiver arma, usa a função padrão do Delta ou Raycast simples
        local WeaponPos = Weapon.CFrame.Position
        local TargetPos = target.Position
        
        local VectorToTarget = (TargetPos - WeaponPos).Unit * 5
        local BodyThrust = Instance.new("BodyThrust")
        BodyThrust.Name = "AttackForce"
        BodyThrust.Parent = Weapon
        
        BodyThrust.Velocity = VectorToTarget
        
        task.wait(0.2) -- Tempo de ataque
        BodyThrust:Destroy()
    end
end

-- Função Principal do Loop
while true do
    local Item = workspace:FindFirstChild(ItemName) or workspace:FindFirstChildWhichIsA("Model", ItemName)
    
    if not Item then
        print("Item não encontrado. Trocando de ilha...")
        
        -- Tenta achar em outras ilhas ou teletransporta para uma nova coordenada
        local NewPos = Islands[(CurrentIslandIndex % #Islands) + 1]
        
        Delta.MoveTo(NewPos, Speed * 2) -- Teleporte rápido para a próxima ilha
        
        task.wait(3) -- Espera chegar na nova ilha
        CurrentIslandIndex = (CurrentIslandIndex % #Islands) + 1
        
    else
        print("Item encontrado! Movendo...")
        
        -- Move até o item suavemente
        Delta.MoveTo(Item, Speed)
        
        task.wait(0.5) -- Pequena pausa para alinhar
        
        -- Ataca até quebrar
        while Item and Item.Parent ~= workspace do
            Delta.Attack(Item)
            
            -- Verifica se o item ainda existe (se foi coletado ou destruído)
            if not workspace:FindFirstChild(ItemName) then
                break
            end
            
            task.wait(AttackDelay)
        end
        
        print("Item coletado!")
        
        -- Se não houver mais nenhum na área, troca de ilha
        local ItemCount = 0
        for _, child in ipairs(workspace:GetDescendants()) do
            if child.Name == ItemName then
                ItemCount = ItemCount + 1
            end
        end
        
        if ItemCount <= 0 then
            print("Sem mais itens na área. Trocando de ilha...")
            Delta.MoveTo(Islands[CurrentIslandIndex], Speed * 2)
            task.wait(3)
            CurrentIslandIndex = (CurrentIslandIndex % #Islands) + 1
        end
    end
    
    -- Loop principal com um pequeno delay para não travar o jogo
    task.wait(0.5)
end
