-- =====================================================================
-- EXPERT PRODUCTION: MIDDLE TOWN PUMPKIN AUTOFARM (SEA 1 EXCLUSIVE)
-- =====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Configurações de Controle Estável
_G.FarmCidadeCentral = false
local TeclaToggle = Enum.KeyCode.E
local VelocidadeVoo = 300 -- Calibrado para o mapa urbano da Cidade Central

-- [RESOLUÇÃO DEFINITIVA DO NIL VALUE]: Captura dinâmica por assinatura de rede
local AttackEvent = nil
local function EscanearRede()
    for _, folder in pairs(ReplicatedStorage:GetChildren()) do
        if folder:IsA("Folder") and (folder.Name == "Net" or folder.Name == "Remotes") then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("RemoteEvent") and (string.find(child.Name, "Attack") or string.find(child.Name, "Click") or child.Name == "打") then
                    AttackEvent = child
                    return
                end
            end
        end
    end
    -- Fallback caso estejam soltos na raiz
    AttackEvent = ReplicatedStorage:FindFirstChild("RegisterAttack") or ReplicatedStorage:FindFirstChild("CombatClick")
end
EscanearRede()

-- Mecanismo de Ataque e Colisão Braçal (Sem travar o interpretador Luau)
local function ExecutarDanoReal()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local tool = Character:FindFirstChildWhichIsA("Tool")
    
    -- Auto-Equip Inteligente da Mochila (Melee)
    if not tool then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in pairs(backpack:GetChildren()) do
                if item:IsA("Tool") and (item.ToolTip == "Melee" or item.Name == "Combat" or item.Name == "Combate") then
                    item.Parent = Character
                    tool = item
                    break
                end
            end
        end
    end

    -- Dispara a ativação local da arma
    if tool then 
        tool:Activate() 
    end

    -- FireServer protegido por tipo para blindar contra chamadas nulas
    if AttackEvent and typeof(AttackEvent) == "Instance" and AttackEvent:IsA("RemoteEvent") then
        pcall(function()
            AttackEvent:FireServer()
        end)
    end
end

-- Deslocamento Direto Sem Tween (Imune ao reset de posicionamento urbano)
local function MoverSeguro(posicaoDestino)
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    humanoid.PlatformStand = true -- Bloqueia travas de animação do jogo
    
    while _G.FarmCidadeCentral and (hrp.Position - posicaoDestino.p).Magnitude > 4 do
        task.wait()
        local vetorDirecao = (posicaoDestino.p - hrp.Position).Unit
        hrp.Velocity = Vector3.new(0, 0, 0) -- Evita gravidade residual do Roblox
        hrp.CFrame = hrp.CFrame + (vetorDirecao * (VelocidadeVoo * task.wait()))
    end
    
    if _G.FarmCidadeCentral then
        hrp.CFrame = posicaoDestino
    end
end

-- Loop de Varredura e Ataque (Focado exclusivamente nas Abóboras do mapa)
task.spawn(function()
    while true do
        task.wait(0.5)
        
        if _G.FarmCidadeCentral then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                -- Varre as instâncias físicas do Workspace de forma recursiva
                for _, object in pairs(Workspace:GetDescendants()) do
                    if not _G.FarmCidadeCentral then break end
                    
                    -- Filtra objetos com colisão ativa cujo nome possui a propriedade "pumpkin"
                    if object:IsA("BasePart") and string.find(string.lower(object.Name), "pumpkin") then
                        -- Ignora efeitos e feixes visuais menores
                        if object.CanCollide == false and object.Size.Magnitude < 1 then
                            continue
                        end
                        
                        -- Alinha o jogador 1.5 studs acima e vira o vetor CFrame de cabeça para baixo encarando o alvo
                        local targetCFrame = object.CFrame * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                        
                        MoverSeguro(targetCFrame)
                        
                        -- Aplica os hits cíclicos até que a abóbora suma por completo do jogo
                        while _G.FarmCidadeCentral and object and object.Parent do
                            task.wait(0.02) -- Velocidade Fast Attack calibrada por frame
                            
                            if hrp and object then
                                hrp.CFrame = object.CFrame * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                            end
                            
                            ExecutarDanoReal()
                        end
                    end
                end
            end
        end
    end
end)

-- Gatilho de Entrada via Input Teclado (Tecla E)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TeclaToggle then
        _G.FarmCidadeCentral = not _G.FarmCidadeCentral
        print("[!] SISTEMA CENTRAL - Modulação do Farm:", _G.FarmCidadeCentral and "ATIVADO" or "DESATIVADO")
        
        if not _G.FarmCidadeCentral then
            Character = LocalPlayer.Character
            local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if humanoid then 
                humanoid.PlatformStand = false -- Restaura movimentação padrão
            end
        end
    end
end)
