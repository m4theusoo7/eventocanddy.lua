-- =====================================================================
-- SCRIPT ESPECIALISTA: AUTO PUMPKIN GRIND (SEA 1 OPTIMIZED)
-- =====================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Configurações Globais
_G.FarmPumpkinsSea1 = false
local TeclaToggle = Enum.KeyCode.E
local VelocidadeVoo = 320 -- Velocidade calibrada padrão para farm de baús/itens no Sea 1

-- Identificação automática dos remotes de combate oficiais do Blox Fruits
local Net = ReplicatedStorage:FindFirstChild("Net") or ReplicatedStorage:FindFirstChild("Remotes")
local RemoteAtaque = Net and (Net:FindFirstChild("RegisterAttack") or Net:FindFirstChild("CombatClick") or Net:FindFirstChild("打"))

-- [SISTEMA DE MOVIMENTAÇÃO DINÂMICA]: Corta a física e viaja sem bugar em ilhas do Sea 1
local function VoarAteAbobora(posicaoCFrame)
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    -- Anula temporariamente animações de queda e atrito físico do jogo
    local estadoAnterior = humanoid.PlatformStand
    humanoid.PlatformStand = true
    
    -- Injeta uma força estabilizadora para o boneco não tremer ou deslizar no ar
    local estabilizador = hrp:FindFirstChild("AntiBugForce") or Instance.new("BodyVelocity")
    estabilizador.Name = "AntiBugForce"
    estabilizador.Velocity = Vector3.new(0, 0, 0)
    estabilizador.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    estabilizador.Parent = hrp

    local distancia = (hrp.Position - posicaoCFrame.p).Magnitude
    local tempoVoo = distancia / VelocidadeVoo

    -- Executa o trajeto linear e aguarda a conclusão exata
    local tween = TweenService:Create(hrp, TweenInfo.new(tempoVoo, Enum.EasingStyle.Linear), {CFrame = posicaoCFrame})
    tween:Play()
    tween.Completed:Wait()

    -- Remove o estabilizador para liberar o personagem ao chegar
    if estabilizador then estabilizador:Destroy() end
    humanoid.PlatformStand = estadoAnterior
end

-- [MECANISMO DE FAST ATTACK]: Força o servidor a computar o hit
local function ExecutarDanoBypass()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    
    -- Auto-Equip do estilo de luta (Combate/Melee) sem quebrar o script
    local ferramenta = Character:FindFirstChildWhichIsA("Tool")
    if not ferramenta then
        local mochila = LocalPlayer:FindFirstChild("Backpack")
        if mochila then
            for _, item in pairs(mochila:GetChildren()) do
                if item:IsA("Tool") and (item.ToolTip == "Melee" or item.Name == "Combat" or item.Name == "Combate") then
                    item.Parent = Character
                    ferramenta = item
                    break
                end
            end
        end
    end

    -- Aciona a animação física local
    if ferramenta then ferramenta:Activate() end

    -- Envia o pacote de dano diretamente ao servidor
    if RemoteAtaque then
        pcall(function()
            RemoteAtaque:FireServer()
        end)
    end
end

-- [LOOP PRINCIPAL DE VARREDURA]: Caça um por um no Sea 1
task.spawn(function()
    while true do
        task.wait(0.5)
        
        if _G.FarmPumpkinsSea1 then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                -- Varre recursivamente todas as estruturas do mapa em busca de modelos de abóbora
                for _, objeto in pairs(game:GetService("Workspace"):GetDescendants()) do
                    if not _G.FarmPumpkinsSea1 then break end
                    
                    -- Verifica se é um modelo válido de evento e se o nome contém "pumpkin"
                    if objeto:IsA("Model") and string.find(string.lower(objeto.Name), "pumpkin") then
                        local blocoFisico = objeto:FindFirstChildWhichIsA("BasePart")
                        
                        -- Garante que o objeto ainda está gerado e ativo no mapa
                        if blocoFisico and blocoFisico.Parent then
                            -- Define a posição: 2 studs acima do item, rotacionando o personagem de cabeça para baixo para acertar em cheio
                            local pontoDestino = blocoFisico.CFrame * CFrame.new(0, 2, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                            
                            -- Move suavemente até o item
                            VoarAteAbobora(pontoDestino)
                            
                            -- Loop de ataque contínuo focado no item atual até ele sumir por completo
                            while _G.FarmPumpkinsSea1 and objeto and objeto.Parent and blocoFisico and blocoFisico.Parent do
                                task.wait(0.01) -- Frequência ultra rápida do Fast Attack
                                
                                -- Trava a posição milimetricamente contra empurrões externos ou rebotes
                                if hrp and blocoFisico then
                                    hrp.CFrame = blocoFisico.CFrame * CFrame.new(0, 2, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                                end
                                
                                -- Desfere o golpe no servidor
                                ExecutarDanoBypass()
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Captura o pressionamento da Tecla E para ligar/desligar de forma limpa
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TeclaToggle then
        _G.FarmPumpkinsSea1 = not _G.FarmPumpkinsSea1
        print("[!] SEA 1 FARM PUMPKIN:", _G.FarmPumpkinsSea1 and "LIGADO" or "DESLIGADO")
        
        -- Limpeza imediata dos modificadores físicos ao desativar
        if not _G.FarmPumpkinsSea1 then
            Character = LocalPlayer.Character
            local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
            if humanoid then humanoid.PlatformStand = false end
            if hrp and hrp:FindFirstChild("AntiBugForce") then hrp.AntiBugForce:Destroy() end
        end
    end
end)
