local Players = game.Players
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Configurações
local ItemName = "Pumpkin" -- Nome do item/modelo a ser buscado
local Speed = 20           -- Velocidade de movimento
local AttackDelay = 0.5    -- Tempo entre ataques
local IslandSwitchCooldown = 10 

-- Tabela de Coordenadas das Ilhas (Exemplos)
local Islands = {
    [1] = Vector3.new(246, -79, 58),
    [2] = Vector3.new(-100, -100, 100),
    [3] = Vector3.new(400, 0, 50),
}

local CurrentIslandIndex = 1

-- Função auxiliar para extrair a posição real (seja de um Vector3, BasePart ou Model)
local function GetTargetPosition(target)
    if typeof(target) == "Vector3" then
        return target
    elseif target:IsA("BasePart") then
        return target.Position
    elseif target:IsA("Model") then
        -- Tenta pegar o Pivot ou a PrimaryPart do modelo
        local success, pivot = pcall(function() return target:GetPivot().Position end)
        if success then return pivot end
        if target.PrimaryPart then return target.PrimaryPart.Position end
    end
    return nil
end

-- Função para Teleporte Suave usando a nova API de Física (LinearVelocity)
local function MoveTo(target, speedMultiplier)
    if not target then return end
    local targetPos = GetTargetPosition(target)
    if not targetPos then return end

    local currentRoot = Character:FindFirstChild("HumanoidRootPart")
    if not currentRoot then return end

    -- Cria um Attachment no HumanoidRootPart para aplicar a força moderna
    local attachment = Instance.new("Attachment")
    attachment.Name = "MoveAttachment"
    attachment.Parent = currentRoot

    -- Cria o LinearVelocity (substituto do BodyVelocity)
    local linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.Attachment0 = attachment
    linearVelocity.MaxForce = math.huge
    linearVelocity.VectorVelocity = Vector3.zero
    linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    linearVelocity.Parent = currentRoot

    -- Controla o movimento suave até a posição alvo
    local distance = (currentRoot.Position - targetPos).Magnitude
    while distance > 5 and currentRoot and targetPos do
        -- Atualiza a posição alvo caso o item se mova
        local currentTargetPos = GetTargetPosition(target) or targetPos
        local direction = (currentTargetPos - currentRoot.Position).Unit
        
        linearVelocity.VectorVelocity = direction * (Speed * (speedMultiplier or 1))
        
        distance = (currentRoot.Position - currentTargetPos).Magnitude
        task.wait()
    end

    -- Limpa os componentes de física ao chegar
    linearVelocity:Destroy()
    attachment:Destroy()
end

-- Função para Atacar usando raycast ou ferramentas modernas
local function Attack(target)
    if not target then return end
    local targetPos = GetTargetPosition(target)
    if not targetPos then return end

    local weapon = Character:FindFirstChildOfClass("Tool") or Character:FindFirstChild("RightHand")
    
    if weapon and weapon:IsA("Tool") then
        -- Se o jogador estiver segurando uma ferramenta, ativa ela
        pcall(function()
            weapon:Activate()
        end)
    else
        -- Alternativa moderna usando impulso linear curto ou simulação de clique/ataque
        local attachment = Instance.new("Attachment")
        attachment.Parent = HumanoidRootPart

        local linearVelocity = Instance.new("LinearVelocity")
        linearVelocity.Attachment0 = attachment
        linearVelocity.MaxForce = 10000
        linearVelocity.VectorVelocity = (targetPos - HumanoidRootPart.Position).Unit * 15
        linearVelocity.Parent = HumanoidRootPart

        task.wait(0.15)
        linearVelocity:Destroy()
        attachment:Destroy()
    end
end

-- Função segura para encontrar um item no Workspace pelo nome
local function FindItem()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant.Name == ItemName then
            if descendant:IsA("Model") or descendant:IsA("BasePart") then
                return descendant
            end
        end
    end
    return nil
end

-- Loop Principal
while true do
    -- Atualiza a referência do personagem caso ele tenha morrido/respawnado
    Character = Player.Character or Player.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    local item = FindItem()

    if not item then
        print("Item não encontrado. Trocando para a ilha " .. CurrentIslandIndex)
        local newPos = Islands[CurrentIslandIndex]
        
        MoveTo(newPos, 2) -- Move mais rápido entre as ilhas
        
        CurrentIslandIndex = (CurrentIslandIndex % #Islands) + 1
        task.wait(2)
    else
        print("Item encontrado! Movendo...")
        MoveTo(item, 1)

        task.wait(0.3)

        -- Ataca enquanto o item existir no workspace
        while item and item.Parent ~= nil do
            Attack(item)
            
            -- Verifica se o item ainda existe
            if not item.Parent or item.Parent == nil then
                break
            end
            
            task.wait(AttackDelay)
        end

        print("Item coletado/destruído!")
        task.wait(0.5)
    end

    task.wait(0.5)
end
