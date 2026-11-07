--[[
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
