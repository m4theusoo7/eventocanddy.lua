-- =============================================================================
-- SCRIPT: AUTO FARM BLOX FRUITS (LEVE & OTIMIZADO)
-- =============================================================================

-- Variável de controle para ativar/desativar o farm
local _G.AutoFarm = true

-- Serviços essenciais do Roblox
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- Evita desconexão por inatividade (Anti-AFK)
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0,0))
end)

-- FUNÇÃO: Encontrar o NPC vivo mais próximo do jogador
local function obterNpcMaisProximo()
    local menorDistancia = math.huge
    local npcAlvo = nil
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then 
        return nil 
    end
    
    local posicaoJogador = character.HumanoidRootPart.Position

    -- No Blox Fruits, os NPCs ficam localizados na pasta Enemies (ou diretamente no Workspace dependendo do Sea)
    local pastaInimigos = Workspace:FindFirstChild("Enemies") or Workspace

    for _, npc in pairs(pastaInimigos:GetChildren()) do
        -- Verifica se é um NPC válido, se está vivo e possui corpo físico
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            if npc.Humanoid.Health > 0 then
                local distancia = (npc.HumanoidRootPart.Position - posicaoJogador).Magnitude
                -- Seleciona apenas o que estiver mais perto
                if distancia < menorDistancia then
                    menorDistancia = distancia
                    npcAlvo = npc
                end
            end
        end
    end
    return npcAlvo
end

-- FUNÇÃO: Equipar a ferramenta de combate automática (Soco/Espada)
local function equiparArma()
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Verifica se já não tem algo equipado
    if not character:FindFirstChildOfClass("Tool") then
        local mochila = LocalPlayer:FindFirstChildOfClass("Backpack")
        if mochila then
            -- Procura por "Combat", "Dark Blade", ou qualquer ferramenta disponível na mochila
            for _, item in pairs(mochila:GetChildren()) do
                if item:IsA("Tool") then
                    item.Parent = character -- Equipa o item
                    break
                end
            end
        end
    end
end

-- LOOP PRINCIPAL DO AUTO FARM
task.spawn(function()
    while _G.AutoFarm do
        -- Intervalo padrão de segurança para não travar a CPU ou dar crash no executor
        task.wait(0.1) 
        
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid").Health > 0 then
            
            local alvo = obterNpcMaisProximo()
            
            if alvo then
                -- 1. Garante que a ferramenta está na mão para atacar
                equiparArma()
                
                -- 2. Teleporta/Move o personagem para trás ou acima do NPC (evita tomar dano excessivo)
                -- Modifica o CFrame para ficar a 4 studs de distância do alvo
                character.HumanoidRootPart.CFrame = alvo.HumanoidRootPart.CFrame * CFrame.new(0, 4, 2)
                
                -- 3. Executa o ataque básico simulando o clique do mouse
                VirtualUser:CaptureController()
                VirtualUser:Button1Down(Vector2.new(0,0))
                
                -- Desativa a colisão entre o jogador e o NPC para evitar bugs de empurrão
                if alvo:FindFirstChild("HumanoidRootPart") then
                    alvo.HumanoidRootPart.CanCollide = false
                end
            end
        end
    end
end)--[[
    Script de Auto Farm - Blox Fruits
    Compatível com: Delta, Fluxus, Hydrogen, Arceus X
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Configurações básicas do Auto Farm
local AutoFarmAtivo = true
local DistanciaMaxima = 350 -- Raio de busca por inimigos

-- Função para equipar automaticamente uma arma (Espada ou Estilo de Luta/Melee)
local function equiparArma()
    local personagem = LocalPlayer.Character
    if not personagem then return end
    
    -- Procura na mochila por ferramentas do tipo Melee ou Sword
    for _, ferramenta in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if ferramenta:IsA("Tool") then
            local tooltip = ferramenta.ToolTip or ""
            if tooltip == "Melee" or tooltip == "Sword" or tooltip:find("Blox Fruit") == nil then
                personagem.Humanoid:EquipTool(ferramenta)
                break
            end
        end
    end
end

-- Função para localizar o NPC/Inimigo mais próximo na pasta padrão do Blox Fruits (Workspace.Enemies)
local function obterInimigoMaisProximo()
    local personagem = LocalPlayer.Character
    if not personagem or not personagem:FindFirstChild("HumanoidRootPart") then return nil end
    
    local raizJogador = personagem.HumanoidRootPart
    local inimigoMaisProximo = nil
    local menorDistancia = DistanciaMaxima
    
    local pastaInimigos = Workspace:FindFirstChild("Enemies")
    if pastaInimigos then
        for _, inimigo in ipairs(pastaInimigos:GetChildren()) do
            local raizInimigo = inimigo:FindFirstChild("HumanoidRootPart")
            local humanoideInimigo = inimigo:FindFirstChild("Humanoid")
            
            -- Verifica se o inimigo está vivo e possui parte física válida
            if raizInimigo and humanoideInimigo and humanoideInimigo.Health > 0 then
                local distancia = (raizJogador.Position - raizInimigo.Position).Magnitude
                if distancia < menorDistancia then
                    menorDistancia = distancia
                    inimigoMaisProximo = inimigo
                end
            end
        end
    end
    
    return inimigoMaisProximo
end

-- Função para realizar o ataque e movimentação até o alvo
local function atacarAlvo(alvo)
    if not alvo or not alvo:FindFirstChild("HumanoidRootPart") then return end
    
    local personagem = LocalPlayer.Character
    if not personagem or not personagem:FindFirstChild("HumanoidRootPart") then return end
    
    -- Teleporta levemente acima/perto do NPC para focar o farm
    personagem.HumanoidRootPart.CFrame = alvo.HumanoidRootPart.CFrame * CFrame.new(0, 5, 3)
    
    -- Garante que a arma está em mãos
    equiparArma()
    
    -- Simula o clique do mouse para desferir o ataque básico (soco ou golpe da arma)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

-- Loop contínuo de execução do Auto Farm com espaçamento para evitar travamento do jogo
task.spawn(function()
    while AutoFarmAtivo do
        pcall(function()
            local alvoAtual = obterInimigoMaisProximo()
            if alvoAtual then
                atacarAlvo(alvoAtual)
            end
        end)
        -- Intervalo em segundos para garantir estabilidade e leveza no executor
        task.wait(0.25)
    end
end)
