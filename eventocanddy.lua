-- Configurações Iniciais
local Settings = {
    Range = 15,              -- Distância máxima para detectar abóboras (em studs)
    Speed = 20,              -- Velocidade de movimento (ajuste conforme sua fruta)
    WaitTime = 3.0,          -- Tempo de espera após coletar uma abóbora
    FruitName = "Watermelon" -- Fruta recomendada para farmar rápido
}

-- Variáveis Principais
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character:FindFirstChild("Humanoid")

if not HumanoidRootPart then return end

-- Função para encontrar a abóbora mais próxima
local function FindNearestPumpkin()
    local pumpkins = workspace:GetChildren()
    
    -- Filtra apenas partes que parecem ser abóboras (ajuste o nome se necessário)
    local targets = {}
    for _, part in ipairs(pumpkins) do
        if part.Name:lower():find("pumpkin") or part.Name == "Pumpkin" then
            table.insert(targets, part)
        end
    end
    
    -- Ordena por distância e retorna a mais próxima
    local nearest = nil
    local minDistance = Settings.Range + 10
    
    for _, target in ipairs(targets) do
        if not target:IsA("Model") and not target:IsA("Part") then continue end
        
        local dist = HumanoidRootPart:Distance(target.Position)
        
        -- Verifica se está dentro da distância de detecção e não muito longe para evitar lag
        if dist < minDistance then
            nearest = target
            minDistance = dist
        end
    end
    
    return nearest, minDistance
end

-- Função principal do loop
local function FarmLoop()
    while true do
        local pumpkin, distance = FindNearestPumpkin()
        
        if pumpkin and distance < Settings.Range then
            -- Se encontrou uma abóbora próxima, move até ela
            local targetPos = pumpkin.Position
            
            -- Ajusta a altura para não colidir com o chão (opcional)
            local offset = CFrame.new(0, 2, 0) 
            local finalCFrame = CFrame.fromAxis(targetPos - HumanoidRootPart.Position + offset) * CFrame.new(HumanoidRootPart.CFrame.LookVector.X, 0, HumanoidRootPart.CFrame.LookVector.Z)
            
            -- Move suavemente até a posição da abóbora
            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame:Lerp(CFrame.fromAxis(targetPos), 1) * CFrame.new(0, 2, 0)
            
            -- Pequeno delay para garantir que o jogo detecte a proximidade
            wait(1.5)
            
            -- Se estiver muito perto (ex: 3 studs), considera coletado e espera um pouco
            if HumanoidRootPart:Distance(pumpkin.Position) < 4 then
                print("Abóbora coletada!")
                wait(Settings.WaitTime)
            end
            
        else
            -- Se não houver abóboras próximas, move para a última posição conhecida ou pausa levemente
            wait(0.5)
        end
    end
end

-- Inicia o loop
FarmLoop()
