-- ====================================================================
-- CONFIGURAÇÕES PRINCIPAIS (Altere os valores abaixo como quiser)
-- ====================================================================
local DISTANCIA_ALVO = 5       -- DISTÂNCIA: Mude este número para alterar os studs de distância do alvo
local DELAY_ATAQUE    = 0.5     -- DELAY: Tempo em segundos entre cada ataque
local TECLA_ATIVAR    = "h"     -- TECLA: Tecla para ligar/desligar o script (letras minúsculas)
-- ====================================================================

-- Serviços do Roblox
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Variáveis de controle
local LocalPlayer = Players.LocalPlayer
local scriptAtivo = false

-- Função para encontrar a Pumpkin mais próxima
local function obterAboboraMaisProxima()
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then return nil end
    
    local meuHRP = localCharacter.HumanoidRootPart
    local alvoMaisProximo = nil
    local menorDistancia = math.huge

    -- Percorre todos os objetos do Workspace procurando por "Pumpkin"
    for _, objeto in ipairs(Workspace:GetDescendants()) do
        if objeto.Name == "Pumpkin" and objeto:IsA("BasePart") then
            local distancia = (objeto.Position - meuHRP.Position).Magnitude
            if distancia < menorDistancia then
                menorDistancia = distancia
                alvoMaisProximo = objeto
            end
        end
    end
    return alvoMaisProximo
end

-- Função para mover o personagem suavemente usando Tween
local function moverSuave(hrp, posicaoAlvo)
    local infoTween = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local objetivo = {CFrame = CFrame.new(posicaoAlvo)}
    local tween = TweenService:Create(hrp, infoTween, objetivo)
    tween:Play()
    tween.Completed:Wait() -- Espera o movimento acabar
end

-- Loop Principal da Execução
task.spawn(function()
    while true do
        task.wait(0.1)
        
        if scriptAtivo then
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            
            -- Se o personagem morrer, desliga o script por segurança
            if not humanoid or humanoid.Health <= 0 or not hrp then
                scriptAtivo = false
                print("[Script] Você morreu ou personagem sumiu. Script desligado.")
                continue
            end

            -- Busca a abóbora mais próxima
            local abobora = obterAboboraMaisProxima()
            
            if abobora and abobora.Parent then
                -- Calcula a posição final respeitando a distância de studs configurada
                local direcao = (hrp.Position - abobora.Position).Unit
                local posicaoFinal = abobora.Position + (direcao * DISTANCIA_ALVO)
                
                -- Se estiver longe, move suavemente
                if (hrp.Position - abobora.Position).Magnitude > (DISTANCIA_ALVO + 1) then
                    moverSuave(hrp, posicaoFinal)
                else
                    -- Quando estiver perto, fica atacando em loop até o objeto sumir/ser destruído
                    while scriptAtivo and abobora and abobora.Parent and (humanoid.Health > 0) do
                        -- Simula o clique/ataque básico (Modifique esta linha se seu jogo usar ferramenta ou evento de ataque específico)
                        local ferramenta = character:FindFirstChildOfClass("Tool")
                        if ferramenta then
                            ferramenta:Activate()
                        else
                            -- Caso o ataque seja por clique virtual se não tiver ferramenta equipada
                            local combate = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                            if combate then 
                                humanoid:EquipTool(combate)
                                combate:Activate()
                            end
                        end
                        task.wait(DELAY_ATAQUE)
                    end
                end
            else
                -- Se não encontrar nenhuma abóbora, para o script
                scriptAtivo = false
                print("[Script] Nenhuma 'Pumpkin' encontrada no mapa. Parando script.")
            end
        end
    end
end)

-- Detector da tecla para Ligar/Desligar
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode[TECLA_ATIVAR:upper()] then
        scriptAtivo = not scriptAtivo
        print("[Script] Estado alterado! Ativo:", scriptAtivo)
    end
end)
