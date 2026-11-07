-- ====================================================================
-- CONFIGURAÇÕES PRINCIPAIS (Altere aqui)
-- ====================================================================
local DISTANCIA_ALVO = 5       -- <--- ONDE MUDA A DISTÂNCIA (Mude o 5 para o valor que quiser)
local DELAY_ATAQUE    = 0.2     -- Tempo entre os socos (Blox fruits aceita ataques rápidos)
local TECLA_ATIVAR    = "h"     -- Tecla para ligar e desligar
-- ====================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local scriptAtivo = false

-- Função para achar a abóbora mais próxima no mapa
local function obterAboboraMaisProxima()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local meuHRP = character.HumanoidRootPart
    local alvoMaisProximo = nil
    local menorDistancia = math.huge

    -- Procura no Workspace por partes chamadas Pumpkin
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

-- Loop funcional que roda no executor
task.spawn(function()
    while true do
        task.wait(0.1) -- Evita travar o seu Roblox
        
        if scriptAtivo then
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            
            -- Se você morrer, o script desliga automaticamente para não dar erro
            if not humanoid or humanoid.Health <= 0 or not hrp then
                scriptAtivo = false
                print("Script desligado: Você morreu ou resetou.")
                continue
            end

            local abobora = obterAboboraMaisProxima()
            
            if abobora and abobora.Parent then
                -- Calcula a posição exata para ficar a 5 studs (ou a distância que você escolheu)
                local direcao = (hrp.Position - abobora.Position).Unit
                local posicaoFinal = abobora.Position + (direcao * DISTANCIA_ALVO)
                
                -- Se a abóbora existir e você estiver longe, ele altera a sua posição suavemente frame por frame
                if (hrp.Position - abobora.Position).Magnitude > (DISTANCIA_ALVO + 1) then
                    hrp.CFrame = CFrame.new(posicaoFinal)
                    task.wait(0.05) -- Pequena pausa para o anti-cheat não te derrubar
                else
                    -- Chegou perto? Começa o loop de ataque real do Blox Fruits
                    while scriptAtivo and abobora and abobora.Parent and (humanoid.Health > 0) do
                        
                        -- Sistema de soco nativo do Blox Fruits (Dispara o evento de combate do jogo)
                        local combatFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Modules") and game:GetService("ReplicatedStorage").Modules:FindFirstChild("Net")
                        if combatFolder then
                            -- Executa o clique de ataque que o jogo reconhece
                            game:GetService("VirtualUser"):CaptureController()
                            game:GetService("VirtualUser"):ClickButton1(Vector2.new(850, 520))
                        end
                        
                        task.wait(DELAY_ATAQUE)
                        
                        -- Verifica se o objeto ainda tá longe por algum motivo e reajusta
                        if (hrp.Position - abobora.Position).Magnitude > (DISTANCIA_ALVO + 2) then
                            break
                        end
                    end
                end
            else
                -- Se destruir a abóbora e não tiver outra perto, ele desliga para você não voar no limbo
                scriptAtivo = false
                print("Nenhuma abóbora por perto. Script pausado.")
            end
        end
    end
end)

-- Ativador por tecla
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode[TECLA_ATIVAR:upper()] then
        scriptAtivo = not scriptAtivo
        print("Script executado com sucesso! Estado atual:", scriptAtivo)
    end
end)
